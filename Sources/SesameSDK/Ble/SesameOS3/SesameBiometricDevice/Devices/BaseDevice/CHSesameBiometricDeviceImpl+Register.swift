//
//  CHSesameBiometricDeviceImpl+Register.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBiometricDeviceImpl {

    public func register(result: @escaping CHResult<CHEmpty>) {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()

        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp, count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey) + timestampData
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)

        CHAPIClient.shared.registerDevice(
            deviceId: self.deviceId.uuidString,
            productType: Int((advertisement?.productType?.rawValue) ?? productModel.rawValue),
            publicKey: self.mSesameToken!.toHexString()
        ) { response in
            switch response {
            case .success(_):
                self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                    let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[0...63].bytes))[0...15]
                    let sessionAuth = CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16)

                    self.cipher = SesameOS3BleCipher(
                        name: self.deviceId.uuidString,
                        sessionKey: sessionAuth,
                        sessionToken: ("00\(self.mSesameToken!.toHexString())").hexStringtoData()
                    )

                    self.sesame2KeyData = CHDeviceKey(
                        deviceUUID: self.deviceId,
                        deviceModel: self.productModel.deviceModel(),
                        historyTag: nil,
                        keyIndex: "0000",
                        secretKey: ecdhSecretPre16.toHexString(),
                        sesame2PublicKey: self.mSesameToken!.toHexString()
                    )

                    self.isRegistered = true
                    self.goIOT()
                    CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!)
                    self.deviceStatus = .unlocked()
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                }

            case .failure(let error):
                L.d("[biometric]register error", error)
                result(.failure(error))
                self.disconnect() { _ in }
            }
        }
    }

    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData,
              let sessionToken = mSesameToken else {
            return
        }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString, sessionKey: sessionAuth, sessionToken: ("00" + sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { _ in
            self.deviceStatus = .unlocked()
        }
    }
}
