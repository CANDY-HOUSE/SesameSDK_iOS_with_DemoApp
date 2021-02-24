//
//  CHSesameBot+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit.UIColor
#if os(iOS)
import SesameSDK
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

extension CHSesameBot {
    func compare(_ switchDevice: CHSesameBot) -> Bool {
        return deviceId.uuidString < switchDevice.deviceId.uuidString
    }
    
    func localizedDescription() -> String {
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
            @unknown default:
                return .lockGray
            }
        }
    }
    
    func currentStatusImage() -> String {
        if deviceStatus.loginStatus == .logined {
            switch deviceStatus {
            case .locked:
                return "switch-locked"
            case .unlocked:
                return "switch-unlocked"
            case .moved:
                return "switch-locked"
            case .noSettings:
                return "noSettings"
            default:
                return "noBleSignal"
            }
        } else if deviceShadowStatus?.loginStatus() == .logined {
            switch deviceShadowStatus {
            case .lockedWifiModule2:
                return "switch-locked"
            case .unlockedWifiModule2:
                return "switch-unlocked"
            case .movedWifiModule2:
                return "switch-unlocked"
            default:
                return "switch-noBleSignal"
            }
        } else {
            switch deviceStatus {
            case .reset:
                return "noSettings"
            case .noBleSignal:
                return "switch-noBleSignal"
            case .receivedBle:
                return "switch-receivedBle"
            case .bleConnecting:
                return "switch-receivedBle"
            case .waitingGatt:
                return "switch-waitingGatt"
            case .bleLogining:
                return "switch-bleLogining"
            case  .readyToRegister:
                return "switch-bleLogining"
            case  .waitingForAuth:
                return "switch-waitingGatt"
            case  .registering:
                return "switch-bleLogining"
            case  .dfumode:
                return "switch-bleLogining"
            case  .locked:
                return "switch-locked"
            case  .unlocked:
                return "switch-unlocked"
            case  .moved:
                return "switch-locked"
            case  .noSettings:
                return "noSettings"
            case  .waitApConnect:
                return "switch-waitingGatt"
            case  .busy:
                return "switch-bleLogining"
            case  .iotConnected:
                return "switch-bleLogining"
            case  .iotDisconnected:
                return "switch-noBleSignal"
            @unknown default:
                return "switch-noBleSignal"
            }
        }
    }
    
    var sesameBotMode: SesameBotClickMode? {
        SesameBotClickMode.modeForSesameBot(self)
    }
}
