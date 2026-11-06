//
//  CHDeviceKey.swift
//  Sesame2SDK
//
//  Created by tse on 2019/11/8.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation

public class CHDeviceKey: NSObject, NSCopying, Codable {
    enum CodingKeys : String, CodingKey {
        case deviceUUID
        case deviceModel
        case historyTag
        case keyIndex
        case secretKey
        case sesame2PublicKey
    }
    
    public var deviceUUID : UUID
    public var deviceModel : String
    public var historyTag : Data?
    public var keyIndex : String
    public var secretKey : String
    public var sesame2PublicKey : String
    
    public init(deviceUUID: UUID,
         deviceModel: String,
         historyTag: Data?,
         keyIndex: String,
         secretKey: String,
         sesame2PublicKey: String) {
        self.deviceUUID = deviceUUID
        self.deviceModel = deviceModel
        self.keyIndex = keyIndex
        self.secretKey = secretKey
        self.sesame2PublicKey = sesame2PublicKey
        self.historyTag = historyTag
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CHDeviceKey(deviceUUID: deviceUUID,
                               deviceModel: deviceModel,
                               historyTag: historyTag,
                               keyIndex: keyIndex,
                               secretKey: secretKey,
                               sesame2PublicKey: sesame2PublicKey)
        return copy
    }
}
