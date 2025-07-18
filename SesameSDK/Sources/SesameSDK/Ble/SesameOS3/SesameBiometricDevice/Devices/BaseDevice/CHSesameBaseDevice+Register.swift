//
//  CHSesameBaseDevice+Register.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesameBaseDevice {
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

        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t": (advertisement?.productType?.rawValue) ?? productModel.rawValue,
            "pk":self.mSesameToken!.toHexString()
        ] as [String : Any])
//        L.d("[ss5][register] ==>")
        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
//                    L.d("[ss5][register][ok <==]")
//                    L.d("[ss5][register][ble] ==>]")
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
//                        L.d("[ss5][register][ble] <==]")
                        let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[0...63].bytes))[0...15]
                        let sessionAuth = CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16)

                        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,
                                             sessionKey: sessionAuth,
                                                           sessionToken: ("00\(self.mSesameToken!.toHexString())").hexStringtoData())

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
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                        self.deviceStatus = .unlocked()
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[ss5]register error",error)
                    result(.failure(error))
                    self.disconnect(){_ in}
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
            self.deviceStatus = .unlocked()
        }
    }
}
