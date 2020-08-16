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
//        switch deviceStatus {
//        case .reset:
//            return "co.candyhouse.sesame-sdk-test-app.reset".localized
//        case .noSignal:
//            return "co.candyhouse.sesame-sdk-test-app.noSignal".localized
//        case .receiveBle:
//            return "co.candyhouse.sesame-sdk-test-app.receiveBle".localized
//        case .connecting:
//            return "co.candyhouse.sesame-sdk-test-app.connecting".localized
//        case .waitgatt:
//            return "co.candyhouse.sesame-sdk-test-app.waitgatt".localized
//        case .logining:
//            return "co.candyhouse.sesame-sdk-test-app.logining".localized
//        case .readytoRegister:
//            return "co.candyhouse.sesame-sdk-test-app.readytoRegister".localized
//        case .locked:
//            return "co.candyhouse.sesame-sdk-test-app.locked".localized
//        case .unlocked:
//            return "co.candyhouse.sesame-sdk-test-app.unlocked".localized
//        case .nosetting:
//            return "co.candyhouse.sesame-sdk-test-app.nosetting".localized
//        case .moved:
//            return "co.candyhouse.sesame-sdk-test-app.moved".localized
//        case .registing:
//            return "co.candyhouse.sesame-sdk-test-app.registing".localized
//        case .dfumode:
//            return "dfumode"
//        }
        ""
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
