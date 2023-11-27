//
//  CHSesameTouchPro+Register.swift
//  SesameSDK
//
//  Created by tse on 2023/5/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
extension CHSesameTouchProDevice {
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
            let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[0...63].bytes))[0...15]
            let sessionAuth = CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16)

            self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+self.mSesameToken!.toHexString()).hexStringtoData())
            self.sesame2KeyData = CHDeviceKey(// 建立設備
                deviceUUID: self.deviceId,
                deviceModel: self.productModel.deviceModel(),
                historyTag: nil,
                keyIndex: "0000",
                secretKey: ecdhSecretPre16.toHexString(),
                sesame2PublicKey: self.mSesameToken!.toHexString()
            )
            self.isRegistered = true // 設定為已註冊
                CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                self.deviceStatus = .unlocked()
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
    }
}

