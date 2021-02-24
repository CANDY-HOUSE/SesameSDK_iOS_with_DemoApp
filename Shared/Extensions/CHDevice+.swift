//
//  CHDevice+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
import UIKit.UIColor
#else
import SesameWatchKitSDK
import WatchKit
#endif

extension CHDevice {
    var deviceName: String {
        let device = Sesame2Store.shared.propertyFor(self)
        
        if self is CHSesame2 {
            return device?.name ?? "co.candyhouse.sesame2.Sesame".localized
        } else if self is CHSesameBot {
            return device?.name ?? "co.candyhouse.sesame2.SesameBot".localized
        } else if self is CHSesameBike {
            return device?.name ?? "co.candyhouse.sesame2.BikeLock".localized
        } else if self is CHWifiModule2 {
            return device?.name ?? "co.candyhouse.sesame2.WifiModule2".localized
        }
        
        return ""
    }
    
    func setDeviceName(_ deviceName: String) {
        Sesame2Store.shared.saveAttributes(["name": deviceName], for: self)
    }
    
    func currentDistanceInCentimeter() -> Int? {
        guard let rssi = rssi,
            let txPower = txPowerLevel else {
                return nil
        }
        let distance = pow(10.0, ((Double(txPower) - rssi.doubleValue) - 62.0) / 20.0)
        return Int(distance * 100)
    }
    
    func deviceStatusDescription() -> String {
        if let sesame2 = self as? CHSesame2 {
            return sesame2.deviceStatus.description
        } else if let switchDevice = self as? CHSesameBot {
            return switchDevice.deviceStatus.description
        } else if let bikeLock = self as? CHSesameBike {
            return bikeLock.deviceStatus.description
        } else if let wifiModule2 = self as? CHWifiModule2 {
            return wifiModule2.deviceStatus.description
        }
        return ""
    }
    
    func wifiColor() -> UIColor {
        if let sesame2 = self as? CHSesame2 {
            if let loginStatus = sesame2.deviceShadowStatus?.loginStatus(),
               loginStatus == .logined
            {
                return .sesame2Green
            } else {
                return .lockGray
            }
        } else if let sesameBotDevice = self as? CHSesameBot {
            if let loginStatus = sesameBotDevice.deviceShadowStatus?.loginStatus(),
               loginStatus == .logined {
                return .sesame2Green
            } else {
                return .lockGray
            }
        } else if let bikeLock = self as? CHSesameBike {
            if let loginStatus = bikeLock.deviceShadowStatus?.loginStatus(),
               loginStatus == .logined {
                return .sesame2Green
            } else {
                return .lockGray
            }
        } else if let wifiModule2 = self as? CHWifiModule2 {
            if let networkStatus = wifiModule2.networkStatus,
               (networkStatus.isAPWork &&
                    networkStatus.isNetwork &&
                    networkStatus.isIoTWork) == true {
                return .sesame2Green
            } else {
                return .lockGray
            }
        } else {
            return .lockGray
        }
    }
    
    func bluetoothColor() -> UIColor {
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
            return .lockGreen
        case .unlocked:
            return .lockGreen
        case .moved:
            return .lockGreen
        case .noSettings:
            return .lockGreen
        case .registering:
            return .lockGreen
        case .dfumode:
            return .lockGreen
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
    
    func batteryImage() -> String {
        if let sesamee2 = self as? CHSesame2 {
            guard let batteryPercentage = sesamee2.mechStatus?.getBatteryPrecentage() else {
                return "bt0"
            }
            return batteryPercentage < 20 ? "bt0" : batteryPercentage < 50 ? "bt50" : "bt100"
        } else if let switchDevice = self as? CHSesameBot {
            guard let batteryPercentage = switchDevice.mechStatus?.getBatteryPrecentage() else {
                return "bt0"
            }
            return batteryPercentage < 20 ? "bt0" : batteryPercentage < 50 ? "bt50" : "bt100"
        } else if let bikeLock = self as? CHSesameBike {
            guard let batteryPercentage = bikeLock.mechStatus?.getBatteryPrecentage() else {
                return "bt0"
            }
            return batteryPercentage < 20 ? "bt0" : batteryPercentage < 50 ? "bt50" : "bt100"
        } else {
            return ""
        }
    }
    
    func compare(_ device: CHDevice) -> Bool {
        if self is CHSesame2 {
            if device is CHSesame2 {
                return self.deviceName > device.deviceName
            } else {
                return true
            }
        } else if self is CHSesameBot && !(device is CHSesame2) {
            if device is CHSesameBot {
                return self.deviceName > device.deviceName
            } else {
                return true
            }
        } else if self is CHSesameBike && !(device is CHSesame2) && !(device is CHSesameBot) {
            if device is CHSesameBike {
                return self.deviceName > device.deviceName
            } else {
                return true
            }
        } else if self is CHWifiModule2 {
            if device is CHWifiModule2 {
                return self.deviceName > device.deviceName
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
