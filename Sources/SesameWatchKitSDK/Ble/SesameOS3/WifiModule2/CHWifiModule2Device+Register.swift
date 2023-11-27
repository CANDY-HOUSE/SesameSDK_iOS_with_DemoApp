//
//  CHWifiModule2Device+Register.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHWifiModule2Device {
    func register(result: @escaping CHResult<CHEmpty>) {
        if isRegistered {
            result(.failure(NSError.bleInvalidAction))
            return
        }
        
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.bleInvalidAction))
            return
        }

        commandQueue = DispatchQueue(label: "wm2-history", qos: .userInitiated)

        sendCommand(.init(.registerWM2, Data(appKeyPair.publicKey)), isCipher: .plaintext) { response in
            if response.cmdResultCode == .success {
//                L.d("wm2 註冊 ok")
                
                let ecdhSecret = Data(self.appKeyPair.ecdh(remotePublicKey: response.data.bytes))
                
                guard let ecdh_secret_pre16 = ecdhSecret[safeBound: 0...15]?.copyData else {
                    return
                }
                
                self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,
                                     sessionKey: ecdh_secret_pre16,
                                     sessionToken: self.wifiModule2Token!)
//                L.d("wm2 加解密設定 ok",self.wifiModule2Token!.toHexLog())
//                L.d("wm2 加解密設定 ok",ecdh_secret_pre16.toHexLog())

                self.isRegistered = true
                self.deviceStatus = CHDeviceStatus.waitApConnect()
                let deviceKey = CHDeviceKey(
                    deviceUUID: self.deviceId,
                    deviceModel: CHProductModel.wifiModule2.deviceModel(),
                    historyTag: nil,
                    keyIndex: "",
                    secretKey: ecdh_secret_pre16.toHexString(),
                    sesame2PublicKey: ""
                )
                self.sesame2KeyData = deviceKey
                CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!)
                result(.success(CHResultStateNetworks(input: CHEmpty())))
                self.goIOT ()
            } 
        }
    }
    
    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if checkBle(result) {
            result(.failure(NSError.resetDeviceError))
            return
        }
        sendCommand(.init(.resetWM2)) { (responsePayload) in
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
