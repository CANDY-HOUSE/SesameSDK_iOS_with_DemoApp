//
//  CHWifiModule2+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
import SesameSDK
#elseif os(watchOS)
import WatchKit
import SesameWatchKitSDK
#endif

extension CHWifiModule2 {
    public func localizedDescription() -> String {
        switch deviceStatus {
        case .reset:
            return "co.candyhouse.sesame-sdk-test-app.reset".localized
        case .noBleSignal:
            return "co.candyhouse.sesame-sdk-test-app.noBleSignal".localized
        case .receivedBle:
            return "co.candyhouse.sesame-sdk-test-app.receivedBle".localized
        case .bleConnecting:
            return "co.candyhouse.sesame-sdk-test-app.bleConnecting".localized
        case .waitingGatt:
            return "co.candyhouse.sesame-sdk-test-app.waitingGatt".localized
        case .bleLogining:
            return "co.candyhouse.sesame-sdk-test-app.bleLogining".localized
        case .readyToRegister:
            return "co.candyhouse.sesame-sdk-test-app.readyToRegister".localized
        case .locked:
            return "co.candyhouse.sesame-sdk-test-app.locked".localized
        case .unlocked:
            return "co.candyhouse.sesame-sdk-test-app.unlocked".localized
        case .noSettings:
            return "co.candyhouse.sesame-sdk-test-app.noSettings".localized
        case .moved:
            return "co.candyhouse.sesame-sdk-test-app.moved".localized
        case .registering:
            return "co.candyhouse.sesame-sdk-test-app.registering".localized
        case .dfumode:
            return "dfumode"
        case .readyToSetup:
            return "readyToSetup"
        case .settingUp:
            return "settingUp"
        case .setupSucceed:
            return "setupSucceed"
        @unknown default:
            return "unknown"
        }
    }
    
    func currentDistanceInCentimeter() -> Int? {
        guard let rssi = rssi,
            let txPower = txPowerLevel else {
                return nil
        }
        let distance = pow(10.0, ((Double(txPower) - rssi.doubleValue) - 62.0) / 20.0)
        return Int(distance * 100)
    }
}
