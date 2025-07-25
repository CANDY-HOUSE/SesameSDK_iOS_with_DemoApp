//
//  CHSesameBikeDevice+Login.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBikeDevice {
    
    func login(token: String? = nil) {
        guard let keyIndex = sesame2KeyData?.keyIndex.hexStringtoData(),
              let userKey = sesame2KeyData?.secretKey.hexStringtoData(),
              let sesame2KeyData = sesame2KeyData,
              sesame2KeyData.sesame2PublicKey != "" else {
            return
        }
        let sesame2PublicKey = sesame2KeyData.sesame2PublicKey.hexStringtoData()
        self.deviceStatus = .bleLogining()
        
        let sessionToken = appRandomToken + bikeLockSessionToken!
        
        let appPublicKey = appKeyPair.publicKey
        
        let signPayload = keyIndex + appPublicKey + sessionToken

        let sessionAuth: Data
        if let token = token {
            sessionAuth = token.hexStringtoData()
        } else {
            sessionAuth = CC.CMAC.AESCMAC(signPayload, key: userKey)
        }

        let sharedSecret = Data(appKeyPair.ecdh(remotePublicKey: sesame2PublicKey.bytes))[0...15]
        let sessionKey = CC.CMAC.AESCMAC( sessionToken, key: sharedSecret)

        self.cipher = Sesame2BleCipher(name: deviceId.uuidString,
                                           sessionKey: sessionKey,
                                           sessionToken: sessionToken)

        let loginPayload = keyIndex + appPublicKey + appRandomToken + sessionAuth[0...3]
 

        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.sync, .login, loginPayload), isCipher: .plaintext) { res in
            
            if  res.cmdItCode == .login && res.cmdResultCode == .success {

                if let payload = BikeLockLoginResponsePayload.fromData(res.data) {
                    let timeErrorInterval = payload.bikeLockTimeFromNowTime()
                    self.mechStatus = payload.mechStatus
                    self.mechSetting = payload.mechSetting
                    if timeErrorInterval > 3 {
                        self.sendCurrentTime(){_ in}
                    }
                    self.deviceStatus = self.mechStatus!.isInLockRange ? .locked() : .unlocked()
                }
            }
        }
    }

//    func sendSyncTime( payload: Data, _ result: @escaping CHResult<Any>) {
//        let cmdPayload = Sesame2Payload(.update, .time, payload)
//        sendCommand(cmdPayload) { (resp) in
//            result(.success(CHResultStateBLE(input: CHEmpty())))
//        }
//    }
//
    func sendCurrentTime(_ result: @escaping CHResult<Any>) {
        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,
                                 count: MemoryLayout.size(ofValue: timestamp))
        let cmdPayload = Sesame2Payload(.update, .timeNoSig, timestampData)
        if (!self.isBleAvailable(result)) { return }
        sendCommand(cmdPayload) { (resp) in
            if resp.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(NSError.syncTimeError))
            }
        }
    }
}
