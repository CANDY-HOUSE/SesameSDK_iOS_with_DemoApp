//
//  URL+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension URL {
    
    static var sesame2UI: URL {
        URL(string: "ssm://UI")!
    }
    
    func schemaShareKeyValue() -> String? {
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == QRcodeType.sesameKey.rawValue else {
            return nil
        }
        let content = getQuery(name: QRcodeType.sesameKey.rawValue)
        
        return content
    }
    
    func schemaFriendValue() -> String? {
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == QRcodeType.friend.rawValue else {
            return nil
        }
        let content = getQuery(name: QRcodeType.friend.rawValue)
        
        return content
    }
    
    func getQuery(name:String) -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let value = components?.queryItems?.filter({
            return $0.name == name
        })
        return value?.first?.value ?? ""
    }
    
    static func qrCodeURLFromDevice(_ device: CHDevice, deviceName: String, keyLevel: Int, guestKey: String? = nil) -> String? {

        var model = UInt8(device.productModel.rawValue)
        let deviceModel = Data(bytes: &model,
                               count: MemoryLayout.size(ofValue: model))
        
        let deviceKey = device.getKey()!
        if let guestKey = guestKey {
            deviceKey.secretKey = guestKey
        }
        let keydata = deviceModel.toHexString() + deviceKey.secretKey + deviceKey.sesame2PublicKey + deviceKey.keyIndex + deviceKey.deviceUUID.uuidString.replacingOccurrences(of: "-", with: "")
//        L.d("keydata",keydata)
//        L.d("deviceModel",deviceModel.toHexString())
//        L.d("secretKey",deviceKey.secretKey)
//        L.d("sesame2PublicKey",deviceKey.sesame2PublicKey)
//        L.d("keyIndex",deviceKey.keyIndex)

        let littleKey = keydata.dataFromHexadecimalString()?.base64EncodedString()
        
        let sharedKey = QRcodeType.sesameKey.rawValue
        var components = URLComponents()
        components.scheme = URL.sesame2UI.scheme
        components.host = URL.sesame2UI.host
        components.queryItems = [
            URLQueryItem(name: "t", value: sharedKey),
            URLQueryItem(name: sharedKey, value: littleKey),
            URLQueryItem(name: "l", value: String(keyLevel)),
            URLQueryItem(name: "n", value: deviceName)
        ]
        return components.url?.absoluteString
    }
    
    /// 解析 qr-code url
    func deviceKeyFromQRCodeURL() -> CHDeviceKey? {
        guard let sesame2Key = self.schemaShareKeyValue() else {
            return nil
        }
        let b64DeviceKey = sesame2Key
        let deviceData = Data(base64Encoded: b64DeviceKey, options: [])!
        let typeData = deviceData[0...0]
        let type = typeData.uint8

        let model = CHProductModel(rawValue: UInt16(type))!
//        L.d("model",model)
        let secretKeyData = deviceData[1...16]

        // [joi todo] cc check 
        if(model == .sesame5 || model == .sesame5Pro || model == .bikeLock2 || model == .sesameTouch || model == .sesameTouchPro || model == .bleConnector ){
            let publicKeyData = deviceData[17...20]
            let keyIndexData = deviceData[21...22]
            let deviceIdData = deviceData[23...38]

            let secretKey = secretKeyData.toHexString()
            let publicKet = publicKeyData.toHexString()
            let keyIndex = keyIndexData.toHexString()
            let deviceId = deviceIdData.toHexString()

            let deviceKey = CHDeviceKey(deviceUUID: deviceId.noDashtoUUID()!,
                                        deviceModel: CHProductModel(rawValue: UInt16(type))!.deviceModel(),
                                        historyTag: nil,
                                        keyIndex: keyIndex,
                                        secretKey: secretKey,
                                        sesame2PublicKey: publicKet)
            return deviceKey
        }else{
            let publicKeyData = deviceData[17...80]
            let keyIndexData = deviceData[81...82]
            let deviceIdData = deviceData[83...98]

            let secretKey = secretKeyData.toHexString()
            let publicKet = publicKeyData.toHexString()
            let keyIndex = keyIndexData.toHexString()
            let deviceId = deviceIdData.toHexString()

            let deviceKey = CHDeviceKey(deviceUUID: deviceId.noDashtoUUID()!,
                                        deviceModel: CHProductModel(rawValue: UInt16(type))!.deviceModel(),
                                        historyTag: nil,
                                        keyIndex: keyIndex,
                                        secretKey: secretKey,
                                        sesame2PublicKey: publicKet)
            return deviceKey
        }

    }
}
