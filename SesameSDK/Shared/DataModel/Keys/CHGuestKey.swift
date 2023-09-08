//
//  CHGuestKey.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2021/02/08.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation

public struct CHGuestKey: Codable {
    public let guestKeyId: String
    public var keyName: String
    
    enum CodingKeys: String, CodingKey {
        case guestKeyId
        case keyName
    }
}
