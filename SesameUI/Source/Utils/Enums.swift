//
//  Sesame2QRCode.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

enum QRcodeType: String {
    case sk
    case friend
}

enum CHQRKey: String {
    case QREventType = "t"
    case QRValue = "invite"
    case QRKeyLevel = "l"
}

enum SesameDeviceType: Int {
    case sesame2 = 0
    case wifiModule2 = 1
    case sesameBot = 2
    case bikeLock = 3
    case sesame4 = 4
    
    var modelName: String {
        switch self {
        case .sesame2: return "sesame_2"
        case .sesameBot: return "ssmbot_1"
        case .bikeLock: return "bike_1"
        case .wifiModule2: return "wm_2"
        case .sesame4: return "sesame_4"
        }
    }
}
