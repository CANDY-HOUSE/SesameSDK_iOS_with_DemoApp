//
//  CHSesameBleInterface+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit.UIColor
#if os(iOS)
import SesameSDK
#elseif os(watchOS)
import SesameWatchKitSDK
#endif
import CoreLocation

extension CHSesame2 {
    public func compare(_ sesame2: CHSesame2) -> Bool {
        let leftDevice = Sesame2Store.shared.propertyFor(self)
        let rightDevice = Sesame2Store.shared.propertyFor(sesame2)
        if let _ = leftDevice!.name, rightDevice!.name == nil {
            return true
        } else if leftDevice!.name == nil, let _ = rightDevice!.name {
            return false
        } else if let leftName = leftDevice!.name, let rightName = rightDevice!.name {
            return leftName < rightName
        } else {
            return deviceId.uuidString < sesame2.deviceId.uuidString
        }
    }
    
    public func localizedDescription() -> String {
        switch deviceStatus {
        case .reset:
            return "co.candyhouse.sesame2.reset".localized
        case .noBleSignal:
            return "co.candyhouse.sesame2.noBleSignal".localized
        case .receivedBle:
            return "co.candyhouse.sesame2.receivedBle".localized
        case .bleConnecting:
            return "co.candyhouse.sesame2.bleConnecting".localized
        case .waitingGatt:
            return "co.candyhouse.sesame2.waitingGatt".localized
        case .waitingForAuth:
            return "co.candyhouse.sesame2.waitingForAuth".localized
        case .bleLogining:
            return "co.candyhouse.sesame2.bleLogining".localized
        case .readyToRegister:
            return "co.candyhouse.sesame2.readyToRegister".localized
        case .locked:
            return "co.candyhouse.sesame2.locked".localized
        case .unlocked:
            return "co.candyhouse.sesame2.unlocked".localized
        case .noSettings:
            return "co.candyhouse.sesame2.noSettings".localized
        case .moved:
            return "co.candyhouse.sesame2.moved".localized
        case .registering:
            return "co.candyhouse.sesame2.registering".localized
        case .dfumode:
            return "dfumode"
        case .waitApConnect:
            return "waitApConnect"
        case .busy:
            return "busy"
        case .iotConnected:
            return "iotConnected"
        case .iotDisconnected:
            return "iotDisconnected"
        @unknown default:
            return ""
        }
    }
    
    func lockColor() -> UIColor {
        
        if deviceStatus.loginStatus == .logined {
            switch deviceStatus {
            case .locked:
                return .lockRed
            case .unlocked:
                return .lockGreen
            case .noSettings:
                return .lockGray
            case .moved:
                return .lockGreen
            default:
                return .lockGray
            }
        } else if deviceShadowStatus?.loginStatus() == .logined {
            switch deviceShadowStatus {
            case .lockedWifiModule2:
                return .lockRed
            case .unlockedWifiModule2:
                return .lockGreen
            case .movedWifiModule2:
                return .lockGreen
            default:
                return .lockGray
            }
        } else {
            switch deviceStatus {
            case .reset:
                return .lockGray
            case .noBleSignal:
                return .lockGray
            case .receivedBle:
                return .lockYellow
            case .bleConnecting:
                return .lockYellow
            case .waitingGatt:
                return .lockYellow
            case .waitingForAuth:
                return .lockYellow
            case .bleLogining:
                return .lockYellow
            case .readyToRegister:
                return .lockYellow
            case .locked:
                return .lockRed
            case .unlocked:
                return .lockGreen
            case .moved:
                return .lockGreen
            case .noSettings:
                return .lockGray
            case .registering:
                return .lockGray
            case .dfumode:
                return .lockGray
            case .waitApConnect:
                return .lockYellow
            case .busy:
                return .lockYellow
            case .iotConnected:
                return .lockGray
            case .iotDisconnected:
                return .lockGray
            @unknown default:
                return .lockGray
            }
        }
    }
    
    public func currentStatusImage() -> String {
        
        if deviceStatus.loginStatus == .logined {
            switch deviceStatus {
            case .locked:
                return "locked"
            case .unlocked:
                return "unlocked"
            case .moved:
                return "unlocked"
            case .noSettings:
                return "noSettings"
            default:
                return "noBleSignal"
            }
        } else if deviceShadowStatus?.loginStatus() == .logined {
            switch deviceShadowStatus {
            case .lockedWifiModule2:
                return "locked"
            case .unlockedWifiModule2:
                return "unlocked"
            case .movedWifiModule2:
                return "unlocked"
            default:
                return "noBleSignal"
            }
        } else {
            switch deviceStatus {
            case .noBleSignal:
                return "noBleSignal"
            case .receivedBle:
                return "receivedBle"
            case .bleConnecting:
                return "receivedBle"
            case .waitingGatt:
                return "waitingGatt"
            case .bleLogining:
                return "bleLogining"
            case .readyToRegister:
                return "bleLogining"
            case .locked:
                return "locked"
            case .unlocked:
                return "unlocked"
            case .moved:
                return "unlocked"
            case .noSettings:
                return "noSettings"
            case .reset:
                return "noBleSignal"
            case .registering:
                return "bleLogining"
            case .dfumode:
                return "bleLogining"
            case .waitingForAuth:
                return "waitingGatt"
            case .waitApConnect:
                return "noBleSignal"
            case .busy:
                return "noBleSignal"
            case .iotConnected:
                return "noBleSignal"
            case .iotDisconnected:
                return "noBleSignal"
            @unknown default:
                return "noBleSignal"
            }
        }
    }
}
