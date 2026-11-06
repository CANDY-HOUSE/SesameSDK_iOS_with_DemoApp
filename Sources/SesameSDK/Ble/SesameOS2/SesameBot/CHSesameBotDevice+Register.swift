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
                self.onRegisterStage1(er: irer.data.er, result: result)
            }
        }
    }
    
    func onRegisterStage1(er: String, result: @escaping CHResult<CHEmpty>) {
        guard let sessionToken = sesameBotSessionToken else {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        CHBleSupport.host.registerOs2(
            deviceId: deviceId,
            appKey: Data(appKeyPair.publicKey).base64EncodedString(),
            nonce: sessionToken.base64EncodedString(),
            registrationKey: er,
            productType: String(CHProductModel.sesameBot.rawValue)
        ) { response in
            switch response {
            case .success(let registration):
                guard let sig1 = Data(base64Encoded: registration.data.signature),
                      let serverToken = Data(base64Encoded: registration.data.token),
                      let sesamePublicKey = Data(base64Encoded: registration.data.publicKey) else {
                    self.deviceStatus = .readyToRegister()
                    result(.failure(NSError.parseError))
                    return
                }
                self.deviceStatus = .registering()
                self.onRegisterStage2(
                    appKey: self.appKeyPair,
                    sig1: sig1,
                    serverToken: serverToken,
                    sesame2PublicKey: sesamePublicKey,
                    result: result
                )
            case .failure(let error):
                self.deviceStatus = .readyToRegister()
                result(.failure(error))
            }
        }
    }

    func onRegisterStage2(
        appKey: ECC,
        sig1: Data,
        serverToken: Data,
        sesame2PublicKey: Data,
        result: @escaping CHResult<CHEmpty>) {

        guard let ecdhSecret = try? appKey.ecdh(remotePublicKey: sesame2PublicKey.bytes), let sessionToken = sesameBotSessionToken else {
            deviceStatus = .readyToRegister()
            disconnect { _ in }
            result(.failure(NSError.registerError))
            return
        }
        let ecdh_secret_pre16 = Data(bytes: ecdhSecret, count: 16)

        let session_token = serverToken + sessionToken
        let reg_key = CC.CMAC.AESCMAC(session_token, key: ecdh_secret_pre16)//registerKey
        let owner_key = CC.CMAC.AESCMAC(Data("owner_key".bytes) , key: reg_key)
        let session_key = CC.CMAC.AESCMAC( session_token, key: reg_key)

        cipher = Sesame2BleCipher(name: deviceId.uuidString, sessionKey: Data(session_key), sessionToken: session_token)

        let payload = sig1 + Data(appKey.publicKey) + serverToken

        sendCommand(.init(.create, .registration, payload), isCipher: .plaintext) { (response) -> Void in
            guard response.cmdResultCode == .success else {
                result(.failure(NSError.registerError))
                return
            }
            self.registerCompleteHandler(owner_key: owner_key, sesame2PublicKey: sesame2PublicKey, result: result)
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
            L.d("註冊完畢收到設定完時間", response)
            let deviceKey = CHDeviceKey(
                deviceUUID: self.deviceId,
                deviceModel: self.productModel.deviceModel(),
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
            CHBleSupport.keys.save(deviceKey)
            result(.success(CHResultStateNetworks(input:CHEmpty())))
        }
    }

    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
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
                guard let switchFicr = CHSesameBotFICR.fromData(response.data) else {
                    result(.failure(NSError.parseError))
                    return
                }
                result(.success(.init(input: switchFicr)))
            } else {
                result(.failure(NSError.readIrErError))
            }
        }
    }
}
