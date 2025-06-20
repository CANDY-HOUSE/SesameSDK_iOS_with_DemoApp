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
        //        L.d("[bk2]register item",deviceId.uuidString)
        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t": self.advertisement!.productType!.rawValue,
            "pk": self.mSesameToken!.toHexString()
        ])
        
        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
                    // sendCommand內容已在CHSesameOS3裡
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                        self.mechStatus = CHSesameBike2MechStatus.fromData(response.data[0...2])!
                        
                        let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[3...66].bytes))[0...15]
                        
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
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中(why?!
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[stp][bk2]register error",error)
                    result(.failure(error))
                    //                    self.deviceStatus = .waitingForAuth()
                    self.disconnect(){_ in}
                }
            }
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
