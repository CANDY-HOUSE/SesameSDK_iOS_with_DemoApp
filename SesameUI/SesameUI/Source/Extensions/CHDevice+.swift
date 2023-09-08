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
        CHDeviceManager.shared.disableNotification(deviceId: deviceId.uuidString, token: token, name: "Sesame2") { _ in }
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
    
    /// 生成 qr-code 字串
    func qrCodeWithKeyLevel(_ keyLevel: Int, _ result: @escaping (String?)->Void) {
        if keyLevel == KeyLevel.guest.rawValue {
            createGuestKey { getResult in
                if case let .success(guestKey) = getResult {
                    let qrCodeURL = URL.qrCodeURLFromDevice(self, deviceName: self.deviceName, keyLevel: keyLevel, guestKey: guestKey.data)
                    result(qrCodeURL)
                } else {
                    result(nil)
                }
            }
        } else {
            result(URL.qrCodeURLFromDevice(self, deviceName: self.deviceName, keyLevel: keyLevel))
        }
    }
}
