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
    
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
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
        if (self.checkBle(result)) { return }
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
        if(checkBle(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                result(.success(CHResultStateNetworks(input: versionTag)))
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
    }

    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
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
            let time = Sesame5Time.fromData(res.data).time
            let sesameTime = Date(timeIntervalSince1970: TimeInterval(time))
            let timeErrorInterval = sesameTime.timeIntervalSince1970 - Date().timeIntervalSince1970
            if abs(timeErrorInterval) > 3 {
                var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
                let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
                self.sendCommand(.init(.time,timestampData)) { res in
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
            self.deviceStatus = self.mechStatus!.isInLockRange ?.locked() :.unlocked()
            CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!)
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
}
