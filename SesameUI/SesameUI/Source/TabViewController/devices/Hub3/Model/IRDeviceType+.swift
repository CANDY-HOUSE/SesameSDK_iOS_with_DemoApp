//
//  IRDeviceType+.swift
//  SesameUI
//
//  Created by eddy on 2024/6/11.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

extension IRDeviceType {
    static var allTypes: [Int] {
        return [
            IRDeviceType.DEVICE_REMOTE_AIR,
//            IRDeviceType.DEVICE_REMOTE_HW,
//            IRDeviceType.DEVICE_REMOTE_AP,
            IRDeviceType.DEVICE_REMOTE_TV,
//            IRDeviceType.DEVICE_REMOTE_IPTV,
//            IRDeviceType.DEVICE_REMOTE_STB,
//            IRDeviceType.DEVICE_REMOTE_DVD,
//            IRDeviceType.DEVICE_REMOTE_FANS,
//            IRDeviceType.DEVICE_REMOTE_PJT,
            IRDeviceType.DEVICE_REMOTE_LIGHT,
//            IRDeviceType.DEVICE_REMOTE_DC,
//            IRDeviceType.DEVICE_REMOTE_AUDIO,
//            IRDeviceType.DEVICE_REMOTE_ROBOT,
            IRDeviceType.DEVICE_REMOTE_CUSTOM
        ]
    }
    
    static func controlFactory(_ type: Int, _ state: String?) -> UniversalRemoteBehavior {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_AIR:    return ControlAirRemote(state)
        case IRDeviceType.DEVICE_REMOTE_HW:     return ControlWaterHeater()
        case IRDeviceType.DEVICE_REMOTE_AP:     return ControlAirPurifier()
        case IRDeviceType.DEVICE_REMOTE_TV:     return ControlTV()
        case IRDeviceType.DEVICE_REMOTE_IPTV:   return ControlIPTV()
        case IRDeviceType.DEVICE_REMOTE_STB:    return ControlSTB()
        case IRDeviceType.DEVICE_REMOTE_DVD:    return ControlDVDPlayer()
        case IRDeviceType.DEVICE_REMOTE_FANS:   return ControlFans()
        case IRDeviceType.DEVICE_REMOTE_PJT:    return ControlProjector()
        case IRDeviceType.DEVICE_REMOTE_LIGHT:  return ControlRemoteControlLight()
        case IRDeviceType.DEVICE_REMOTE_DC:     return ControlDigitalCamera()
        case IRDeviceType.DEVICE_REMOTE_AUDIO:  return ControlSoundSystem()
        case IRDeviceType.DEVICE_REMOTE_ROBOT:  return ControlVacuumCleaner()
        case IRDeviceType.DEVICE_REMOTE_CUSTOM: return ControlDIY()
        default:
            return ControlDIY()
        }
    }
}
