//
//  WatchKitFileTransfer.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameWatchKitSDK
import WatchConnectivity

final class WatchKitFileTransfer {

    static func receiveUserInfoFromIPhone(_ userInfo: [String: Any]) {
        
        CHDeviceManager.shared.dropAllLocalKeys()
        
        let decoder = JSONDecoder()
        let keys = (userInfo["keys"] as! [String]).compactMap {
            try? decoder.decode(WatchKitFile.self, from: ($0).data(using: .utf8)!)
        }
        
        guard let firstKey = keys.first, let watchHistoryTag = "\(firstKey.historyTag)".data(using: .utf8) else {
            NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
            return
        }
        Sesame2Store.shared.setHistoryTag(watchHistoryTag)
        
        let deviceKeys = keys.compactMap { (item: WatchKitFile) -> CHDeviceKey? in
            let urlString = item.key
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

            return CHDeviceKey(deviceUUID: deviceId.noDashtoUUID()!,
                               deviceModel: SesameDeviceType(rawValue: Int(type))!.modelName,
                               historyTag: nil,
                               keyIndex: keyIndex,
                               secretKey: secretKey,
                               sesame2PublicKey: publicKet)
        }
        
        CHDeviceManager.shared.receiveCHDeviceKeys(deviceKeys) { result in
            if case let .success(devices) = result {
                for device in devices.data {
                    let keyFile = keys.filter{$0.deviceId == device.deviceId.uuidString}.first!
                    device.setDeviceName(keyFile.name)
                }
            }
        }
        CHDeviceManager.shared.setHistoryTag()
        NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
    }
}
