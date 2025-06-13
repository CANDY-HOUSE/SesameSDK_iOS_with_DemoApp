//
//  CHSesame5Device+Register.swift
//  SesameSDK
//  
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

extension CHSesame5Device {
    public func register(result: @escaping CHResult<CHEmpty>)  {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()

        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey)+timestampData
        self.commandQueue = DispatchQueue(label:deviceId.uuidString, qos: .userInitiated)

        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t":advertisement!.productType!.rawValue,
            "pk":self.mSesameToken!.toHexString()
        ])

        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                        // 检查是否为错误响应 长度为4且最后一位为09（错误标记位）
                        // [1001297]嵌入设备在多App同时并发注册时，后注册的设备会返回4个字节长度且最后一位为09的数据。
                        if(response.data.count == 4 && response.data[3] == 0x09){
                            return
                        }
                        self.mechStatus =
                            Sesame5MechStatus.fromData(response.data[0...6])!
                        self.mechSetting = CHSesame5MechSettings.fromData(response.data[7...12])!
                        let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[13...76].bytes))[0...15]

                        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString, sessionKey: CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16),sessionToken: ("00"+self.mSesameToken!.toHexString()).hexStringtoData())

                        self.sesame2KeyData = CHDeviceKey(// 建立設備
                            deviceUUID: self.deviceId,
                            deviceModel: self.productModel.deviceModel(),
                            historyTag: nil,
                            keyIndex: "0000",
                            secretKey: ecdhSecretPre16.toHexString(),
                            sesame2PublicKey: self.mSesameToken!.toHexString()
                        )
                        self.isRegistered = true // 設定為已註冊
                        self.goIOT()
                        self.deviceStatus = self.mechStatus!.isInLockRange  ? .locked() :.unlocked()
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[stp]register error",error)
                    result(.failure(error))
//                    self.deviceStatus = .waitingForAuth()
                    self.disconnect(){_ in}
                }
            }

    }
}

