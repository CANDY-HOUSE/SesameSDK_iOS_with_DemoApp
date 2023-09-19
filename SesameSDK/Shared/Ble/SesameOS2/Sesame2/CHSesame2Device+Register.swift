//
//  CHSesame2Device+Register.swift
//  sesame2-sdk
//  Created by tse on 2019/08/28.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

extension CHSesame2Device {
    public func register(result: @escaping CHResult<CHEmpty>)  {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        getIRER { irerResult in
            if case let .success(irer) = irerResult {
                let ER = irer.data.er
                self.registerDevice(er: ER, result: result)
            } else if case let .failure(error) = irerResult {
                result(.failure(error))
            }
        }
    }
    
    func registerDevice(er: String, result: @escaping CHResult<CHEmpty>) {
        let keyData = KeyQues(
            ak: (Data(appKeyPair.publicKey).base64EncodedString()),
            n: sesame2SessionToken!.base64EncodedString(),
            e: er,
            t: Os2Type.sesame2
        )
        
        let registerKeyResp = Os2CipherUtils.getRegisterKey(data: keyData)
        self.deviceStatus = .registering()
        
        if let sig1 = Data(base64Encoded: registerKeyResp.sig1),
           let serverToken = Data(base64Encoded: registerKeyResp.st),
           let sesame2PublicKey = Data(base64Encoded: registerKeyResp.pubkey) {
            
            let ecdhSecret = self.appKeyPair.ecdh(remotePublicKey: sesame2PublicKey.bytes)
            let ecdh_secret_pre16 = Data(bytes: ecdhSecret, count: 16)
            let session_token = serverToken + sesame2SessionToken!
            
            let reg_key = CC.CMAC.AESCMAC(session_token, key: ecdh_secret_pre16)
            let owner_key = CC.CMAC.AESCMAC(Data("owner_key".bytes), key: reg_key)
            let session_key = CC.CMAC.AESCMAC(session_token, key: reg_key)
            
            cipher = Sesame2BleCipher(name: deviceId.uuidString, sessionKey: Data(session_key), sessionToken: session_token)
            
            let payload = sig1 + Data(appKeyPair.publicKey) + serverToken
            
            sendCommand(.init(.create, .registration, payload), isCipher: .plaintext) {  (response) -> Void in
                self.registerCompleteHandler(owner_key: owner_key, sesame2PublicKey: sesame2PublicKey, result: result)
            }
        } else {
            result(.failure(NSError.parseError))
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
        
    func registerCompleteHandler(owner_key: Data, sesame2PublicKey: Data, result: @escaping CHResult<CHEmpty>) {
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
                result(.failure(NSError.resetDeviceError))
            }
        }
    }
}
