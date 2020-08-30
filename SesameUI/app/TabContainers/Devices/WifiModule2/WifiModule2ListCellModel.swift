//
//  WifiModule2ListCellModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

final class WifiModule2ListCellModel: ViewModel {
    
    public var statusUpdated: ViewStatusHandler?
    private let wifiModule2: CHWifiModule2
    
    init(wifiModule2: CHWifiModule2) {
        self.wifiModule2 = wifiModule2
        wifiModule2.connect(){res in }
        wifiModule2.delegate = self
    }
    
    func batteryImage() -> String {
        ""
    }
    
    func name() -> String {
        wifiModule2.deviceId.uuidString
    }
    
    func ownerName() -> String {
        wifiModule2.deviceStatus.description()
    }
    
    func power() -> String {
        ""
    }
}

extension WifiModule2ListCellModel: CHWifiModule2Delegate {
    public func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHWifiModule2Status) {
        statusUpdated?(.update(nil))
    }
}
