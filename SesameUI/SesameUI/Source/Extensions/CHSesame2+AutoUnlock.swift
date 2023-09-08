//
//  CHSesame2+AutoUnlock.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import SesameSDK
import CoreLocation

extension CHSesameLock {
    // 設定auto unlock
    func setAutoUnlock(_ enable: Bool) {
        let autoUnlockType = enable ? 1 : 0
        Sesame2Store.shared.saveAttributes(["autoUnlockType": autoUnlockType], for: self)
    }
    
    // auto unlock 狀態
    func autoUnlockStatus() -> Bool {
        if let device = Sesame2Store.shared.propertyFor(self) as? Sesame2PropertyMO {
            return Int(device.autoUnlockType) > 0
        } else {
            return false
        }
    }
    
    // 設備 gps 的範圍
    func region() -> CLCircularRegion? {
        guard let device = Sesame2Store.shared.propertyFor(self) as? Sesame2PropertyMO else {
            return nil
        }
        return CLCircularRegion(center: CLLocationCoordinate2D(latitude: device.latitude, longitude: device.longitude), radius: device.radius, identifier: deviceId.uuidString)
    }
}
