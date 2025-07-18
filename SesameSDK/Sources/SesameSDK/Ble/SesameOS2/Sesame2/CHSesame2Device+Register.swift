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
        L.d("[s2註冊][Stage1]")
        let request = CHAPICallObject(.post, "/device/v1/sesame2/\(self.deviceId.uuidString)", [
            "s1": [
                "ak": (Data(appKeyPair.publicKey).base64EncodedString()),
                "n": sesame2SessionToken!.base64EncodedString(),
                "e": er,
                "t": advertisement!.productType!.rawValue
            ] as [String : Any]
        ]
        )
        
        CHAccountManager
            .shared
            .API(request: request) { response in
                L.d("[s2註冊][CHAccountManager]API")
                switch response {
                case .success(let data):
                    guard let data = data else {
                        result(.failure(NSError.noContent))
                        return
                    }
                    // todo kill this parcer with json decoder
                    if let dict = try? data.decodeJsonDictionary() as? [String: String],
                        let b64Sig1 = dict["sig1"],
                        let b64ServerToken = dict["st"],
                        let b64SesamePublicKey = dict["pubkey"],
                        let sig1 = Data(base64Encoded: b64Sig1),
                        let serverToken = Data(base64Encoded: b64ServerToken),
                        let sesamePublicKey = Data(base64Encoded: b64SesamePublicKey) {
                        
                        self.deviceStatus = .registering()
                        
                        self.onRegisterStage2 (
                            appKey: self.appKeyPair,
                            sig1: sig1,
                            serverToken: serverToken,
                            sesame2PublicKey: sesamePublicKey,
                            result: result
                        )
                    } else {
                        result(.failure(NSError.parseError))
                    }
                case .failure(let error):
                    result(.failure(error))
                }
            }
    }
    
    func getIRER(_ result: @escaping CHResult<CHSesameBotFICR>) {
        L.d("[s2註冊][發給設備的指令]")
        sendCommand(.init(.read, .IRER), isCipher: .plaintext) { response in
            if response.cmdResultCode == .success {
                let switchFicr = CHSesameBotFICR.fromData(response.data)!
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
        let ecdhSecret = appKey.ecdh(remotePublicKey: sesame2PublicKey.bytes)
        let ecdh_secret_pre16 = Data(bytes: ecdhSecret, count: 16)

        let session_token = serverToken + sesame2SessionToken!
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
                deviceModel: self.advertisement!.productType!.deviceModel(),
                historyTag:Data(),
                keyIndex: "0000",
                secretKey: owner_key.toHexString(),
                sesame2PublicKey: sesame2PublicKey.toHexString()
            )
            self.sesame2KeyData = deviceKey
            CHDeviceCenter.shared.appendDevice(deviceKey)
            self.deviceStatus = .noSettings()
            self.isRegistered = true
            self.goIOT()
            
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
