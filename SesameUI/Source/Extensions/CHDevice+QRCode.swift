//
//  CHSesame2+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension CHDevice {
    func qrCode(_ result: @escaping (String?)->Void) {
        guard let deviceKey = getKey() else {
            return
        }
        result(URL.qrCodeURLFromDeviceKey(deviceKey, deviceName: self.deviceName))
    }
    
    func deviceKeyFromQRCodeURL(_ urlString: String) -> CHDeviceKey? {
        guard let scanSchema = URL(string: urlString),
              let sesame2Key = scanSchema.schemaShareKeyValue() else {
            return nil
        }
        let b64DeviceKey = sesame2Key
        let deviceData = Data(base64Encoded: b64DeviceKey, options: [])!
        let typeData = deviceData[0...0]
        let secretKeyData = deviceData[1...16]
        let publicKeyData = deviceData[17...80]
        let keyIndexData = deviceData[81...82]
        let deviceIdData = deviceData[83...98]

        let type = typeData.uint8
        let secretKey = secretKeyData.toHexString()
        let publicKet = publicKeyData.toHexString()
        let keyIndex = keyIndexData.toHexString()
        let deviceId = deviceIdData.toHexString()

        let deviceKey = CHDeviceKey(deviceUUID: deviceId.noDashtoUUID()!,
                                    deviceModel: SesameDeviceType(rawValue: Int(type))!.modelName,
                                    historyTag: nil,
                                    keyIndex: keyIndex,
                                    secretKey: secretKey,
                                    sesame2PublicKey: publicKet)
        return deviceKey
    }
}
