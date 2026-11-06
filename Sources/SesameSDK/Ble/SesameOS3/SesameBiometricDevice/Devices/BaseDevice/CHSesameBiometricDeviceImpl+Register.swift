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
        registerWithDevicePublicKey(result: result)
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
