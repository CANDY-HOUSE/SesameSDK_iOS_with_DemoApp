//
//  CHSwitchDevice+Register.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBotDevice {
    public func register(result: @escaping CHResult<CHEmpty>)  {
        
        if self.deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        getIRER { irerResult in
            if case let .success(irer) = irerResult {
                self.makeApiCall(er: irer.data.er, result: result)
            }
        }
    }
    
    func makeApiCall(er: String, result: @escaping CHResult<CHEmpty>) {
        let keyData = KeyQues(
            ak: (Data(appKeyPair.publicKey).base64EncodedString()),
            n: self.sesameBotSessionToken!.base64EncodedString(),
            e: er,
            t: advertisement!.productType!.rawValue
        )
        
        let registerKeyResp = CHServerAuth.getRegisterKey(data: keyData)
        self.deviceStatus = .registering()
        
        if let sig1 = Data(base64Encoded: registerKeyResp.sig1),
           let serverToken = Data(base64Encoded: registerKeyResp.st),
           let sesamePublicKey = Data(base64Encoded: registerKeyResp.pubkey) {
            
            let ecdhSecret = self.appKeyPair.ecdh(remotePublicKey: sesamePublicKey.bytes)
            let ecdhSecretPre16 = Data(bytes: ecdhSecret, count: 16)
            let sessionToken = serverToken + self.sesameBotSessionToken!
            
            let registerKey = CC.CMAC.AESCMAC(sessionToken, key: ecdhSecretPre16)
            let ownerKey = CC.CMAC.AESCMAC(Data("owner_key".bytes), key: registerKey)
            let sessionKey = CC.CMAC.AESCMAC(sessionToken, key: registerKey)
            
            cipher = Sesame2BleCipher(name: deviceId.uuidString, sessionKey: Data(sessionKey), sessionToken: sessionToken)
            
            let payload = sig1 + Data(appKeyPair.publicKey) + serverToken
            
            sendCommand(.init(.create, .registration, payload), isCipher: .plaintext) {  (response) -> Void in
                self.registerCompleteHandler(owner_key: ownerKey, sesame2PublicKey: sesamePublicKey, result: result)
            }
        } else {
            result(.failure(NSError.parseError))
        }
    }

    
    func registerCompleteHandler(owner_key: Data, sesame2PublicKey: Data, result: @escaping CHResult<CHEmpty>) {
        guard self.fwVersion != nil else {
            DispatchQueue.global().async {
                self.registerCompleteHandler(owner_key: owner_key, sesame2PublicKey: sesame2PublicKey, result: result)
            }
            return
        }
        
//        L.d("藍芽", "🀄", "用戶 註冊", "semaphore 重製")
        self.sendCurrentTime { response in
//            L.d("註冊完畢收到設定完時間", response)
            let deviceKey = CHDeviceKey(
                deviceUUID: self.deviceId,
                deviceModel: self.advertisement!.productType!.deviceModel(),
                historyTag:Data() ,
                keyIndex: "0000",
                secretKey: owner_key.toHexString(),
                sesame2PublicKey: sesame2PublicKey.toHexString()
            )
            self.sesame2KeyData = deviceKey
            if let mechStatus = self.mechStatus {
                self.deviceStatus = mechStatus.isInLockRange ? .locked() : mechStatus.isInUnlockRange ? .unlocked() : .moved()
            } else {
                self.deviceStatus = .noSettings()
            }
            
            self.isRegistered = true
            CHDeviceCenter.shared.appendDevice(deviceKey)
            self.goIOT()
            result(.success(CHResultStateNetworks(input:CHEmpty())))
        }
    }

    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        
        sendCommand(.init(.delete, .registration)) { (responsePayload) in
            if responsePayload.cmdResultCode == .success {
                self.dropKey { dropResult in
                    switch dropResult {
                    case .success(_):
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    case .failure(let error):
                        result(.failure(error))
                    }
                }
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func getIRER(_ result: @escaping CHResult<CHSesameBotFICR>) {
        sendCommand(.init(.read, .IRER), isCipher: .plaintext) { response in
            if response.cmdResultCode == .success {
                let switchFicr = CHSesameBotFICR.fromData(response.data)!
                result(.success(.init(input: switchFicr)))
            } else {
                result(.failure(NSError.readIrErError))
            }
        }
    }
}
