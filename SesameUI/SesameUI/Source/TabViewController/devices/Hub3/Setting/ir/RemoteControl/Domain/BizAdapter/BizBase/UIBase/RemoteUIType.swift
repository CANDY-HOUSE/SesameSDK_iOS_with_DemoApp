//
//  RemoteUIType.swift
//  SesameUI
//
//  Created by CANDY HOUSE on 2025/9/14.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

enum RemoteUIType: String {
    case air = "air_control_config"
    case light = "light_control_config"
    case tv = "tv_control_config"
    case fan = "fan_control_config"
    case error = ""
    
    var irType: Int {
        switch self {
        case .air: return IRType.DEVICE_REMOTE_AIR
        case .light: return IRType.DEVICE_REMOTE_LIGHT
        case .tv: return IRType.DEVICE_REMOTE_TV
        case .fan: return IRType.DEVICE_REMOTE_FANS
        case .error: return 0
        }
    }
}
