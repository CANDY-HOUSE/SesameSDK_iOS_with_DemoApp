//
//  CHDevice+.swift
//  CHUserRegister
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/20.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

// MARK: - Reset
extension CHDevice {
    /// 取消通知
    func unregisterNotification() {
        let token = UserDefaults.standard.string(forKey: "devicePushToken")!
        CHAPIClient.shared.disableNotification(deviceId: deviceId.uuidString, token: token, name: "Sesame2") { _ in }
    }
    
    /// 設備距離 cm
    func currentDistanceInCentimeter() -> Int {
        guard let rssi = rssi,
            let txPower = txPowerLevel else {
                return  Int(200)
        }
        let distance = pow(10.0, ((Double(txPower) - rssi.doubleValue) - 62.0) / 20.0)
        return Int(distance * 100)
    }
    
    /// 設備狀態描述
    func deviceStatusDescription() -> String {
        return self.deviceStatus.description
    }
    
    func batteryPercentage() -> Int? {
        if self is CHWifiModule2 {
            return stateInfo?.batteryPercentage
        }
        if let mechStatus = mechStatus {
            return mechStatus.getBatteryPrecentage()
        }
        return stateInfo?.batteryPercentage
    }
}

extension CHDevice {
    func convertToCellDescriptorModel(cellCls: AnyClass, optCallback: ((CHDevice) -> Void)? = nil) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            if let listCell = cell as? Sesame5ListCell {
                listCell.optCallback = optCallback
            }
            cell.configure(item: self)
        }
    }
}

extension CHDevice {
    var userKey: CHUserKey? {
        return CHDeviceWrapperManager.shared.getUserKey(for: deviceId.uuidString)
    }
    
    var stateInfo: StateInfo? {
        return userKey?.stateInfo
    }
}
