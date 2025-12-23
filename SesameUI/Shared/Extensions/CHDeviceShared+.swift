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

    var deviceName: String { /// 設備暱稱
        let device = Sesame2Store.shared.propertyFor(self)
        switch self.productModel {
        case .sesame5:
            return device?.name ?? "\("co.candyhouse.sesame2.Sesame".localized)5"
        case .sesame5Pro:
            return device?.name ?? "\("co.candyhouse.sesame2.Sesame".localized)5 Pro"
        case .sesame2:
            return device?.name ?? "\("co.candyhouse.sesame2.Sesame".localized)3"
        case .sesame4 :
            return device?.name ?? "\("co.candyhouse.sesame2.Sesame".localized)4"
        case .wifiModule2:
            return device?.name ?? "co.candyhouse.sesame2.WifiModule2".localized
        case .sesameBot:
            return device?.name ?? "co.candyhouse.sesame2.SesameBot".localized
        case .bikeLock:
            return device?.name ?? "co.candyhouse.sesame2.BikeLock".localized
        case .bikeLock2:
            return device?.name ?? "co.candyhouse.sesame2.BikeLock2".localized
        case .sesameTouchPro:
            return device?.name ?? "co.candyhouse.sesame2.SSMTouchPro".localized
        case .sesameTouch2Pro:
            return device?.name ?? "co.candyhouse.sesame2.SSMTouchPro2".localized
        case .sesameTouch:
            return device?.name ?? "co.candyhouse.sesame2.SSMTouch".localized
        case .sesameTouch2:
            return device?.name ?? "co.candyhouse.sesame2.SSMTouch2".localized
        case .openSensor:
            return device?.name ?? "co.candyhouse.sesame2.OpenSensor".localized
        case .openSensor2:
            return device?.name ?? "co.candyhouse.sesame2.OpenSensor2".localized
        case .bleConnector:
            return device?.name ?? "co.candyhouse.sesame2.BLEConnector".localized
        case .remote:
            return device?.name ?? "co.candyhouse.sesame2.CHRemote".localized
        case .remoteNano:
            return device?.name ?? "co.candyhouse.sesame2.CHRemoteNano".localized
        case .sesame5US:
            return device?.name ?? "co.candyhouse.sesame2.Sesame5US".localized
        case .sesameBot2:
            return device?.name ?? "co.candyhouse.sesame2.SesameBot2".localized
        case .hub3:
            return device?.name ?? "co.candyhouse.sesame2.Hub3".localized
        case .sesameFacePro:
            return device?.name ?? "co.candyhouse.sesame2.SSMFacePro".localized
        case .sesameFace2Pro:
            return device?.name ?? "co.candyhouse.sesame2.SSMFacePro2".localized
        case .sesameFace:
            return device?.name ?? "co.candyhouse.sesame2.SSMFace".localized
        case .sesameFace2:
            return device?.name ?? "co.candyhouse.sesame2.SSMFace2".localized
        case .sesame6Pro:
            return device?.name ?? "\("co.candyhouse.sesame2.Sesame".localized)6 Pro"
        case .sesameFaceAI:
            return device?.name ?? "co.candyhouse.sesame2.SSMFaceAI".localized
        case .sesameFaceProAI:
            return device?.name ?? "co.candyhouse.sesame2.SSMFaceProAI".localized
        case .none:
            return "develope-device"
        @unknown default:
            return "dev-device"
        }
    }

    func setDeviceName(_ deviceName: String) {/// 設定設備名稱
        Sesame2Store.shared.saveAttributes(["name": deviceName], for: self)
    }

    func batteryIndicatorWidth() -> CGFloat { /// 設備 電池電量長度
        var fullBattery = CGFloat(10.2)
#if os(watchOS)
        fullBattery = CGFloat(12)
#endif
        var batteryPercentage: Int?

        batteryPercentage = self.mechStatus?.getBatteryPrecentage() ?? 0
        //        L.d("batteryPercentage",batteryPercentage)
        let value = 0 + (CGFloat(fullBattery) * CGFloat(batteryPercentage!) / 100)
        return value
    }

    func compare(_ device: CHDevice) -> Bool {  /// 設備排序
        if self.getRank() == device.getRank(){
            return self.deviceName < device.deviceName //改为升序
        }else{
            return self.getRank() > device.getRank() //同樣設備依據名稱排序
        }
    }
    func setRank(level: Int) {
        UserDefaults(suiteName: "group.candyhouse.widget")!.set(level, forKey: self.deviceId.uuidString)
    }

    func getRank() -> Int {
        return UserDefaults(suiteName: "group.candyhouse.widget")!.integer(forKey: self.deviceId.uuidString)
    }
}
extension CHDevice {
    /// 當前設備狀態描述
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


    func lockColor() -> UIColor {/// 當前鎖顏色
        if let sesameLock = self as? CHSesameLock {
            if ((sesameLock.deviceStatus.loginStatus == .logined)  || (sesameLock.deviceShadowStatus != nil)){
                return   mechStatus?.isInLockRange == true    ?   .lockRed : .lockGreen
            }
        }
       return .lockGray
    }


    public func currentStatusImage() -> String { /// 當前狀態圖片
        if let sesameLock = self as? CHSesameLock {
            //            L.d("currentStatusImage!!",deviceStatus.description,deviceShadowStatus?.description,sesameLock.deviceShadowStatus)
            if (sesameLock.deviceShadowStatus != nil){
                if sesameLock is CHSesameBot || sesameLock is CHSesameBot2 {
                    return  mechStatus?.isInLockRange == true ?  "switch-locked":"switch-unlocked"
                }else{
                    return  mechStatus?.isInLockRange == true ?  "locked":"unlocked"
                }
            }
        }
        if self.productModel == .openSensor || self.productModel == .openSensor2 {
            return "opensensor"
        }
        switch deviceStatus {
        case .noBleSignal:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-noBleSignal"
            } else {
                return "noBleSignal"
            }
        case .bleConnecting, .receivedBle:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-receivedBle"
            }else{
                return  "receivedBle"
            }
        case .waitingGatt:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-waitingGatt"
            }else{
                return  "waitingGatt"
            }
        case .bleLogining:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-bleLogining"
            }else{
                return  "bleLogining"
            }
        case .readyToRegister:
            return "bleLogining"
        case .locked:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-locked"
            }else{
                return  "locked"
            }
        case .unlocked:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-unlocked"
            }else{
                return  "unlocked"
            }
        case .moved:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-locked"
            }else{
                return  "locked"
            }
        case .noSettings:
            return "noSettings"
        case .reset:
            return "noBleSignal"
        case .registering:
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-bleLogining"
            }else{
                return  "bleLogining"
            }
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
            if self is CHSesameBot || self is CHSesameBot2 {
                return  "switch-noBleSignal"
            }else{
                return  "noBleSignal"
            }
        }

    }
}


extension CHDevice {
    /// 設定AutoUnlock flag: 出圈後打開 flag, 執行開鎖後關閉flag
    func setAutoUnlockFlag(_ flag: Bool) {
        Sesame2Store.shared.saveAttributes(["autoUnlockFlag": flag], for: self)
    }

    func autoUnlockFlag() -> Bool {
        let prop = Sesame2Store.shared.propertyFor(self) as! Sesame2PropertyMO
        return prop.autoUnlockFlag
    }
}

extension CHDevice {
    /// 設備 wifi icon 顏色
    func wifiColor() -> UIColor {
        if let wifiModule2 = self as? CHWifiModule2 {
            return ((wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isIoTWork  == true) ? .sesame2Green : .lockGray
        }

        if let locker = self as? CHSesameLock {
            return (locker.deviceShadowStatus  != nil) ? .sesame2Green : .lockGray
        }
        if let connector = self as? CHSesameTouchPro {
            return (connector.deviceShadowStatus  != nil) ? .sesame2Green : .lockGray
        }
        if let connector = self as? CHSesameTouch {
            return (connector.deviceShadowStatus  != nil) ? .sesame2Green : .lockGray
        }
        if let connector = self as? CHSesameFace {
            return (connector.deviceShadowStatus  != nil) ? .sesame2Green : .lockGray
        }
        if let connector = self as? CHSesameFacePro {
            return (connector.deviceShadowStatus  != nil) ? .sesame2Green : .lockGray
        }
        return  .lockGray
    }
    
    func wifiImageStr() -> String {
        if wifiColor() == .lockGray {
            return "wifi_gray"
        } else if wifiColor() == .sesame2Green {
            return "wifi_green"
        }
        return "wifi_gray"
    }
    func bluetoothStatusStr() -> String {
        if(self is CHSesameConnector){
            return  (deviceStatus.loginStatus == .logined || deviceStatus == .noBleSignal() || deviceStatus == .receivedBle()) ? "" : deviceStatus.description
        }else{
            return  (deviceStatus.loginStatus == .logined || deviceStatus == .noBleSignal()) ? "" : deviceStatus.description

        }
    }
    func bluetoothImageStr() -> String {
        if bluetoothColor() == .lockGray {
            return "bluetooth_gray"
        } else if bluetoothColor() == .lockYellow {
            return "bluetooth_yellow"
        } else if bluetoothColor() == .sesame2Green {
            return "bluetooth_green"
        } else if bluetoothColor() == .lockRed {
            return "bluetooth_red"
        }
        return "bluetooth_gray"
    }
    /// 設備 藍牙 icon 顏色
    func bluetoothColor() -> UIColor {
        switch deviceStatus {
        case .reset:
            return .lockGray
        case .noBleSignal:
            return .lockGray
        case .receivedBle:
            return .lockGray
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

}
extension CHDevice {
    /// 設定 key level
    func setKeyLevel(_ keyLevel: Int) {
        Sesame2Store.shared.saveAttributes(["keyLevel": keyLevel], for: self)
    }

    /// 取得 key level
    var keyLevel: Int {
        if let device = Sesame2Store.shared.propertyFor(self) {
            return Int(device.keyLevel) 
        } else {
            return KeyLevel.guest.rawValue
        }
    }
}

extension UUID4HistoryTagType {
    var data: Data {
        var value = self.rawValue
        let bigEndian = (value >> 8) | ((value & 0xFF) << 8)
        var convertedValue = bigEndian
        return Data(bytes: &convertedValue, count: 2)
    }
}

extension CHDevice {
    /// 設定 history tag
    var hisTag: Data {
        if let lock = self as? CHSesameLock {
            var tag = lock.getHistoryTag() ?? Data()
            var historyTag = Data()
            if self is CHSesame5 {
                if (deviceShadowStatus != nil && deviceStatus.loginStatus == .unlogined) || !self.isBleAvailable() {
                    historyTag.append(UUID4HistoryTagType.nameUuidTypeIosUserWifiUuid.data)
                    historyTag.append(tag)
                } else {
                    historyTag.append(UUID4HistoryTagType.nameUuidTypeIosUserBleUuid.data)
                    historyTag.append(tag)
                }
                
            }
            return historyTag
        }
        return Data()
    }
}

