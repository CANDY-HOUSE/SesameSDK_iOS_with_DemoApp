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
                self.makeApiCall(er: irer.data.er, result: result)
            } else if case let .failure(error) = irerResult {
                result(.failure(error))
            }
        }
    }
    
    func makeApiCall(er: String, result: @escaping CHResult<CHEmpty>) {
        let keyData = KeyQues(
            ak: (Data(appKeyPair.publicKey).base64EncodedString()),
            n: sesame2SessionToken!.base64EncodedString(),
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
            let sessionToken = serverToken + sesame2SessionToken!
            
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
