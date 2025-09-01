//
//  CHDeviceUtil+OS3.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/25.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

// os3下的通用工具集合
extension CHDeviceUtil where Self: CHSesameOS3 & CHDevice {
    
    /// 登录
    /// - Parameter token: 用戶token
    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else { return }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { [weak self] res in
            guard let self = self else { return }
            self.handleLoginReceived(res)
        }
    }
    
    /// 處理登陸結果需要歷史紀錄時才需要同步時間
    /// - Parameter res: response
    func handleLoginReceived(_ res: SesameOS3CmdResponsePayload) {
        guard let _ = self as? CHSesame5 else { return }
        let  time = Sesame5Time.fromData(res.data).time
        let sesameTime = Date(timeIntervalSince1970: TimeInterval(time))
        //            L.d("[bk2][time]", sesameTime.description(with: .current))
        //            L.d("[bk2][phonetime]", Date().description(with: .current))
        let timeErrorInterval = sesameTime.timeIntervalSince1970 - Date().timeIntervalSince1970
        //            L.d("[ss5][timeErrorInterval]", timeErrorInterval)
        if abs(timeErrorInterval) > 3 {
            //                L.d("[bk2][timeErrorInterval>3]", timeErrorInterval)
            var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
            let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
            self.sendCommand(.init(.time,timestampData)) { res in
                //                    L.d("[bk2][cmd]", timeErrorInterval,res.cmdResultCode.plainName)
            }
        }
    }
    
    /// 註冊配對
    /// - Parameter result: 返回結果
    func register(result: @escaping CHResult<CHEmpty>)  {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()
        
        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey)+timestampData
        self.commandQueue = DispatchQueue(label:deviceId.uuidString, qos: .userInitiated)
        
        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t":advertisement!.productType!.rawValue,
            "pk":self.mSesameToken!.toHexString()
        ])
        
        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                        // 检查是否为错误响应 长度为4且最后一位为09（错误标记位）
                        // [1001297]嵌入设备在多App同时并发注册时，后注册的设备会返回4个字节长度且最后一位为09的数据。
                        if(response.data.count == 4 && response.data[3] == 0x09){
                            return
                        }
                        var ecdhSecretPre16 = Data()
                        if (self.appKeyPair.havePubKey(remotePublicKey: response.data[13...76].bytes)) { // 新协议
                            ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[13...76].bytes))[0...15]
                            self.mechStatus = Sesame5MechStatus.fromData(response.data[0...6])!
                        } else {
                            ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[3...66].bytes))[0...15]
                            self.mechStatus = CHSesameBike2MechStatus.fromData(response.data[0...2])!
                        }
                        
                        if let sesame5Device = self as? CHSesame5Device {
                            sesame5Device.mechSetting = CHSesame5MechSettings.fromData(response.data[7...12])!
                        }
                        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString, sessionKey: CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16),sessionToken: ("00"+self.mSesameToken!.toHexString()).hexStringtoData())
                        
                        self.sesame2KeyData = CHDeviceKey(// 建立設備
                            deviceUUID: self.deviceId,
                            deviceModel: self.productModel.deviceModel(),
                            historyTag: nil,
                            keyIndex: "0000",
                            secretKey: ecdhSecretPre16.toHexString(),
                            sesame2PublicKey: self.mSesameToken!.toHexString()
                        )
                        self.isRegistered = true // 設定為已註冊
                        self.goIOT()
                        self.deviceStatus = self.mechStatus!.isInLockRange  ? .locked() :.unlocked()
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[stp]register error",error)
                    result(.failure(error))
                    //                    self.deviceStatus = .waitingForAuth()
                    self.disconnect(){_ in}
                }
            }
    }
    
    func goIOT() {
//        L.d("[bk2][iot]=>[goIOT]")
        if( self.isGuestKey){ return }
        
#if os(iOS)
        CHIoTManager.shared.subscribeCHDeviceShadow(self) { result in
            switch result {
            case .success(let content):
                var isConnectedByWM2 = false
                if let wm2s = content.data.wifiModule2s {
                    isConnectedByWM2 = wm2s.filter({ $0.isConnected == true }).count > 0
                }
                
                if isConnectedByWM2,
                   let mechStatusData = content.data.mechStatus?.hexStringtoData() {
                    if mechStatusData.count >= 7 { // 新固件蓝牙上报长度为7，iot下发的长度为8
                        if let mechStatus = Sesame5MechStatus.fromData(Sesame2MechStatus.fromData(mechStatusData)!.ss5Adapter()) {
                            self.mechStatus = mechStatus
                        }
                    } else {
                        if let mechStatus = CHSesameBike2MechStatus.fromData(mechStatusData) {
                            self.mechStatus = mechStatus
                        }
                    }
                }
                
                if isConnectedByWM2 {
                    self.deviceShadowStatus = (self.mechStatus?.isInLockRange == true) ? .locked() : .unlocked()
                } else {
                    self.deviceShadowStatus = nil
                }
                
                if let sesame5Device = self as? CHSesame5Device {
                    sesame5Device.isConnectedByWM2 = isConnectedByWM2
                }
            case .failure( _): break
            }
        }
#endif
    }
    
    /// 更新固件
    /// - Parameter result: 返回 peripheral
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }
    
    /// 獲取固件當前版本號
    /// - Parameter result: 版本號
    func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                L.d("[bot2][getVersionTag =>]",versionTag)
                result(.success(CHResultStateNetworks(input: versionTag)))
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
    }
    
    /// 重置設備
    /// - Parameter result: 返回結果
    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.reset)) { (responsePayload) in
            self.dropKey { dropResult in
                switch dropResult {
                case .success(_):
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
    }
    
}
