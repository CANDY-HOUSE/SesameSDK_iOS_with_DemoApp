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
        self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
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
        self.deviceStatus = self.mechStatus!.isInLockRange  ? .locked() :.unlocked()
        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
        result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
}


