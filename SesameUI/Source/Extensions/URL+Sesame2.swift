//
//  URL+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

extension URL {
    
    static var sesame2UI: URL {
        URL(string: "ssm://UI")!
    }
    
    func schemaShareKeyValue() -> String? {
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == QRcodeType.sk.rawValue else {
            return nil
        }
        
        L.d("scanSchema", self)
        let content = getQuery(name: QRcodeType.sk.rawValue)
        L.d("🔑","content",content)
        
        return content
    }
    
    func schemaFriendValue() -> String? {
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == QRcodeType.friend.rawValue else {
            return nil
        }
        
        L.d("scanSchema", self)
        let content = getQuery(name: QRcodeType.friend.rawValue)
        L.d("🔑","content",content)
        
        return content
    }
    
    func getQuery(name:String) -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let value = components?.queryItems?.filter({
            return $0.name == name
        })
        return value?.first?.value ?? ""
    }
    
    static func qrCodeURLFromDeviceKey(_ deviceKey: CHDeviceKey, deviceName: String) -> String? {
        
        var deviceModel: Data!
        if deviceKey.deviceModel == SesameDeviceType.sesame2.modelName {
            var model = UInt8(SesameDeviceType.sesame2.rawValue)
            deviceModel = Data(bytes: &model,
                               count: MemoryLayout.size(ofValue: model))
        } else if deviceKey.deviceModel == SesameDeviceType.sesameBot.modelName {
            var model = UInt8(SesameDeviceType.sesameBot.rawValue)
            deviceModel = Data(bytes: &model,
                               count: MemoryLayout.size(ofValue: model))
        } else if deviceKey.deviceModel == SesameDeviceType.bikeLock.modelName {
            var model = UInt8(SesameDeviceType.bikeLock.rawValue)
            deviceModel = Data(bytes: &model,
                               count: MemoryLayout.size(ofValue: model))
        } else if deviceKey.deviceModel == SesameDeviceType.sesame4.modelName {
            var model = UInt8(SesameDeviceType.sesame4.rawValue)
            deviceModel = Data(bytes: &model,
                               count: MemoryLayout.size(ofValue: model))
        }
        
        let keydata = deviceModel.toHexString() + deviceKey.secretKey + deviceKey.sesame2PublicKey + deviceKey.keyIndex + deviceKey.deviceUUID.uuidString.replacingOccurrences(of: "-", with: "")
        let littleKey = keydata.dataFromHexadecimalString()?.base64EncodedString()
        
        let sharedKey = QRcodeType.sk.rawValue
        var components = URLComponents()
        components.scheme = URL.sesame2UI.scheme
        components.host = URL.sesame2UI.host
//        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "t", value: sharedKey),
            URLQueryItem(name: sharedKey, value: littleKey),
            URLQueryItem(name: "n", value: deviceName)
        ]
        return components.url?.absoluteString
    }
}
