//
//  WifiModule2Protocols.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/5.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

enum WifiModule2ActionCode: UInt8, CustomStringConvertible {
    case none               = 0
    case registerWM2        = 1
    case loginWM2           = 2
    case updateWifiSSID     = 3
    case updateWifiPassword = 4
    case connectWifi        = 5
    case networkStatus      = 6
    case deleteSesame2      = 7
    case addSesame2         = 8
    case initial            = 13
    case cccd               = 14
    case sesame2Keys        = 16
    case resetWM2           = 18
    case scanWifiSSID       = 19
    case openOTAServer      = 126
    case versionTag         = 127

    var description: String {
        return String(format: "actionCode:%d", self.rawValue)
    }
    
    var plainName: String {
        switch self {
        
        case .none:
            return "none"
        case .registerWM2:
            return "registerWM2"
        case .loginWM2:
            return "loginWM2"
        case .updateWifiSSID:
            return "updateWifiSSID"
        case .updateWifiPassword:
            return "updateWifiPassword"
        case .connectWifi:
            return "connectWifi"
        case .networkStatus:
            return "networkStatus"
        case .deleteSesame2:
            return "deleteSesame2"
        case .addSesame2:
            return "addSesame2"
        case .initial:
            return "initial"
        case .cccd:
            return "cccd"
        case .sesame2Keys:
            return "sesame2Keys"
        case .resetWM2:
            return "resetWM2"
        case .scanWifiSSID:
            return "scanWifiSSID"
        case .openOTAServer:
            return "openOTAServer"
        case .versionTag:
            return "versionTag"
        }
    }
}

public struct CHSSID: Equatable {
    public let name: String
    public let rssi: Int16
    
    public static func == (lhs: CHSSID, rhs: CHSSID) -> Bool {
        return lhs.name == rhs.name
    }
}
