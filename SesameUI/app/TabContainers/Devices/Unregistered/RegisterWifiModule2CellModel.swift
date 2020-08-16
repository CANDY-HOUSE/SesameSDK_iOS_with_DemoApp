//
//  RegisterWifiModule2CellModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public protocol RegisterWifiModule2CellModelDelegate: class {
    func registerWifiModule2Succeed()
}

public final class RegisterWifiModule2CellModel: ViewModel {
    private var wifiModule2: CHWifiModule2!
    public var statusUpdated: ViewStatusHandler?
    public var delegate: RegisterWifiModule2CellModelDelegate?
    
    public init(wifiModule2: CHWifiModule2) {
        self.wifiModule2 = wifiModule2
    }
    
    public func rssi() -> String {
        guard let currentDistanceInCentimeter = wifiModule2.currentDistanceInCentimeter() else {
            return ""
        }
        return "\(currentDistanceInCentimeter) \("co.candyhouse.sesame-sdk-test-app.cm".localized)"
    }
    
    public func bluetoothImage() -> String {
        "bluetooth"
    }
    
    public func deviceName() -> String {
        wifiModule2.deviceId.uuidString
    }
    
    public func deviceStatus() -> String {
        wifiModule2.localizedDescription()
    }
}
