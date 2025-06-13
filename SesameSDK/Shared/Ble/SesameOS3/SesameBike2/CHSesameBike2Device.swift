//
//  CHSesameBike2Device.swift
//  SesameSDK
//
//  Created by JOi Chao on 2023/5/30.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBike2Device: CHSesameOS3 ,CHSesameBike2, CHDeviceUtil {

    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
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
                   let mechStatusData = content.data.mechStatus?.hexStringtoData(),
                   let mechStatus = CHSesameBike2MechStatus.fromData(mechStatusData) {
                    self.mechStatus = mechStatus
                }
                
                if isConnectedByWM2 {
                    self.deviceShadowStatus = (self.mechStatus?.isInLockRange == true) ? .locked() : .unlocked()
                }else{
                    self.deviceShadowStatus = nil
                }
            case .failure( _): break
            }
        }
#endif
    }
    


    override  func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {
        case .mechStatus:
            mechStatus = CHSesameBike2MechStatus.fromData(data)!
            self.deviceStatus = mechStatus!.isInLockRange  ? .locked() :.unlocked()

        default:
            L.d("[bk2][publish]!![\(itemCode.rawValue)]")
        }
    }
}


extension CHSesameBike2Device {

    public func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        let hisTag = Data.createOS2Histag(historytag ?? self.sesame2KeyData?.historyTag)
        sendCommand(.init(.unlock,hisTag)) { responsePayload in
//            L.d("[bk2][unlock][sendCommand] res =>",responsePayload.cmdResultCode)
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }

    public func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                L.d("[bk2][getVersionTag =>]",versionTag)
                result(.success(CHResultStateNetworks(input: versionTag)))
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
    }

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

    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else {
            return
        }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { res in
//            L.d("[bk2][login]",res.data.toHexString())
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
    }


}

extension CHSesameBike2Device {
    public func register(result: @escaping CHResult<CHEmpty>)  {
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
            "t":advertisement!.productType!.rawValue,
            "pk":self.mSesameToken!.toHexString()
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
}
