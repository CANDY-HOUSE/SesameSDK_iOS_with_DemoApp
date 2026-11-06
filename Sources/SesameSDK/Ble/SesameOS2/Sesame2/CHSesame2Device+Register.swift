//
//  CHSesame2Device+Register.swift
//  sesame2-sdk
//
//  Created by tse on 2019/08/28.
//  Copyright © 2019 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesame2Device {
    public func register(result: @escaping CHResult<CHEmpty>)  {
        L.d("[s2註冊]")
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }

        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        getIRER { irerResult in
            if case let .success(irer) = irerResult {
                self.onRegisterStage1(er: irer.data.er, result: result)
            } else if case let .failure(error) = irerResult {
                result(.failure(error))
            }
        }
    }
    
    func onRegisterStage1(er: String, result: @escaping CHResult<CHEmpty>) {
        guard let sessionToken = sesame2SessionToken else {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        CHBleSupport.host.registerOs2(
            deviceId: deviceId,
            appKey: Data(appKeyPair.publicKey).base64EncodedString(),
            nonce: sessionToken.base64EncodedString(),
            registrationKey: er,
            productType: String((advertisement?.productType ?? productModel).rawValue)
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
    
    func getIRER(_ result: @escaping CHResult<CHSesameBotFICR>) {
        L.d("[s2註冊][發給設備的指令]")
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

    func onRegisterStage2 (

        appKey: ECC,
        sig1: Data,
        serverToken: Data,
        sesame2PublicKey: Data,
        result: @escaping CHResult<CHEmpty>) {
        L.d("[s2註冊][Stage2]")
        guard let ecdhSecret = try? appKey.ecdh(remotePublicKey: sesame2PublicKey.bytes), let sessionToken = sesame2SessionToken else {
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
        
        sendCommand(.init(.create, .registration, payload), isCipher: .plaintext) {  (response) -> Void in
            self.registerCompleteHandler(owner_key: owner_key, sesame2PublicKey: sesame2PublicKey, result: result)
        }
    }
    
    func registerCompleteHandler(owner_key: Data, sesame2PublicKey: Data, result: @escaping CHResult<CHEmpty>) {
        L.d("[s2註冊][完成]")
        guard self.fwVersion != nil else {
            DispatchQueue.global().async {
                self.registerCompleteHandler(owner_key: owner_key, sesame2PublicKey: sesame2PublicKey, result: result)
            }
            return
        }
        
        self.sendCurrentTime { res in
            let deviceKey = CHDeviceKey(
                deviceUUID: self.deviceId,
                deviceModel: self.productModel.deviceModel(),
                historyTag:Data(),
                keyIndex: "0000",
                secretKey: owner_key.toHexString(),
                sesame2PublicKey: sesame2PublicKey.toHexString()
            )
            self.sesame2KeyData = deviceKey
            CHBleSupport.keys.save(deviceKey)
            self.deviceStatus = .noSettings()
            self.isRegistered = true
            
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
                result(.failure(NSError.resetDeviceError))
            }
        }
    }
}
