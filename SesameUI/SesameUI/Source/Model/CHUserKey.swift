//
//  CHUserKey.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2020/11/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

struct CHUserKey: Codable {
    let deviceModel: String?
    let deviceUUID: String
    let keyIndex: String?
    var keyLevel: Int?
    var subUUID: String?
    var secretKey: String?
    let sesame2PublicKey: String?
    var deviceName: String?
    var rank: Int?

    func toCHDevice() -> CHDevice? {
        var device: CHDevice?
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                device = devices.data.filter {
                    $0.deviceId.uuidString == deviceUUID
                }.first
            }
        }
        return device
    }
    
    func getKey() -> CHDeviceKey? {
        guard let uuid = UUID(uuidString: deviceUUID),
              let deviceModel = deviceModel,
              let keyIndex = keyIndex,
              let secretKey = secretKey,
              let sesame2PublicKey = sesame2PublicKey else {
            return nil
        }
            
        return CHDeviceKey(deviceUUID: uuid,
                    deviceModel: deviceModel,
                    historyTag: nil,
                    keyIndex: keyIndex,
                    secretKey: secretKey,
                    sesame2PublicKey: sesame2PublicKey)
    }
    
    static func fromCHDevice(_ device: CHDevice) -> CHUserKey {
        return userKeyFromCHDevice(device, keyLevel: device.keyLevel,rank: device.getRank())
    }
    
    static func userKeyFromCHDevice(_ device: CHDevice, keyLevel: Int,rank:Int? = nil) -> CHUserKey {
        guard let deviceKey = device.getKey() else {
            return CHUserKey(deviceModel: nil,
                             deviceUUID: device.deviceId.uuidString,
                             keyIndex: nil,
                             keyLevel: keyLevel,
                             subUUID: nil,
                             secretKey: nil,
                             sesame2PublicKey: nil,
                             deviceName: device.deviceName,
                             rank: rank
            )
        }
        var userKey = CHUserKey(deviceModel: deviceKey.deviceModel,
                            deviceUUID: deviceKey.deviceUUID.uuidString,
                            keyIndex: deviceKey.keyIndex,
                            keyLevel: keyLevel,
                            subUUID: nil,
                            secretKey: deviceKey.secretKey,
                            sesame2PublicKey: deviceKey.sesame2PublicKey,
                            deviceName: device.deviceName,
                                rank: rank
        )
        
        if let device = userKey.toCHDevice(), let deviceName = Sesame2Store.shared.propertyFor(device)?.name {
            userKey.deviceName = deviceName
        }
        return userKey
    }
}
