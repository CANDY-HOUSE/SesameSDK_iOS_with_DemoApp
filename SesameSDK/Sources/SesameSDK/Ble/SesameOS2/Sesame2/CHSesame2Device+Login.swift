//
//  Sesame2BleLogin.swift
//  Sesame2SDK
//
//  Created by tse on 2019/09/11.
//  Copyright © 2019 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesame2Device {
    
    func login(token: String? = nil) {
        //        L.d(customNickname,"💙","登入 mSesame2Token",mSesame2Token!.toHexString())
        guard let keyIndex = sesame2KeyData?.keyIndex.hexStringtoData(),
              let userKey = sesame2KeyData?.secretKey.hexStringtoData(),
              let sesame2KeyData = sesame2KeyData,
              sesame2KeyData.sesame2PublicKey != "" else {
            return
        }
        let sesame2PublicKey = sesame2KeyData.sesame2PublicKey.hexStringtoData()
//        L.d("🏈 Login sesame2 secretKey:", sesame2KeyData!.secretKey)
        self.deviceStatus = .bleLogining()
        let sessionToken = appRandomToken + sesame2SessionToken!
        
//        let appKeyPair = ECC.generate()
        let appPublicKey = appKeyPair.publicKey
//        L.d("🌇","login app publicKey",appKeyPair.publicKey.toHexString(),appKeyPair.publicKey.count)
        
        let signPayload = keyIndex + appPublicKey + sessionToken

        let sessionAuth: Data
        if let token = token {
//         L.d("💙","登入 mSesame2Token ++ ")
            sessionAuth = token.hexStringtoData()
        } else {
//            L.d("💙","登入 mSesame2Token -- ")
            sessionAuth = CC.CMAC.AESCMAC(signPayload, key: userKey)
        }

        let sharedSecret = Data(appKeyPair.ecdh(remotePublicKey: sesame2PublicKey.bytes))[0...15]
        let sessionKey = CC.CMAC.AESCMAC( sessionToken, key: sharedSecret)

        self.cipher = Sesame2BleCipher(name: deviceId.uuidString,
                                       sessionKey: sessionKey,
                                       sessionToken: sessionToken)
        let loginPayload = keyIndex + appPublicKey + appRandomToken + sessionAuth[0...3]
//        L.d("藍芽", "🀄", "用戶 Login", "semaphore 重製 ")
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        semaphoreSesame?.signal()
        semaphoreSesame = DispatchSemaphore(value: 0)
        semaphoreSesame?.signal()
        
        sendCommand(.init(.sync, .login, loginPayload), isCipher: .plaintext) { res in
            
            if res.cmdItCode == .login && res.cmdResultCode == .success {
//                L.d("🚢->","Login","success")

                if let payload = Sesame2LoginResponsePayload.fromData(res.data) {
                    let sesameTime = Date(timeIntervalSince1970: TimeInterval(payload.systemTime))
//                    L.d("time", "sesameTime", sesameTime.description(with: .current))
//                    L.d("time", "phoneTime", Date().description(with: .current))
                    let timeErrorInterval = payload.sesame2TimeFromNowTime()
                    self.mechStatus = payload.mechStatus
                    self.mechSetting = payload.mechSetting
                    self.fwVersion = payload.fwVersion
//                    self.historyCnt = UInt16(payload.historyCnt)
                    if abs(timeErrorInterval) > 3 {
                        if let fwVersion = self.fwVersion, fwVersion > 0 {
//                            L.d("time", "sendCurrentTime")
                            self.sendCurrentTime { _ in }
                        } else {
                            self.requestSyncTime { _ in }
                        }
                    }

                    self.deviceStatus = self.mechSetting!.isConfigured() ?  (self.mechStatus!.isInLockRange ? .locked() : .unlocked()) : .noSettings()
                }
            } else {
//                L.d("🚢->","Login failed")
            }
        }
    }
    
    func requestSyncTime( _ result: @escaping CHResult<Any>) {
        if let sessionToken = self.cipher?.sessionToken {
            let reqBody: NSDictionary = [
                "st": sessionToken.base64EncodedString()
            ]
            
            CHAccountManager
                .shared
                .API(request: .init(.post, "/device/v1/sesame2/\(deviceId.uuidString)/time", reqBody)) { response in
                    switch response {
                    case .success(let data):
                        guard let data = data else {
                            L.d("🕒", NSError.noContent)
                            return
                        }
                        // todo kill this parcer
                        guard let dict = try? data.decodeJsonDictionary() as? NSDictionary,
                              let b64Payload = dict["r"] as? String,
                              let payload = Data(base64Encoded: b64Payload) else {
                            L.d("🕒Parse data failed.")
                            return
                        }
                        self.sendSyncTime(payload: payload){ res in
                            result(.success(CHResultStateBLE(input: CHEmpty())))
                            
                        }
                    case .failure(let error):
                        L.d("🕒",error)
                    }
                }
        }
    }

    func sendSyncTime(payload: Data, _ result: @escaping CHResult<Any>) {
        let cmdPayload = Sesame2Payload(.update, .time, payload)
        
        sendCommand(cmdPayload) { (resp) in
            if resp.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(NSError.syncTimeError))
            }
        }
    }
    
    func sendCurrentTime(_ result: @escaping CHResult<Any>) {
        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,
                                 count: MemoryLayout.size(ofValue: timestamp))
        let cmdPayload = Sesame2Payload(.update, .timeNoSig, timestampData)
        
        sendCommand(cmdPayload) { (resp) in
            if resp.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(NSError.syncTimeError))
            }
        }
    }
}
