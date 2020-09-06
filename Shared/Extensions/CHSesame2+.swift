//
//  CHSesameBleInterface+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit.UIColor
#if os(iOS)
import SesameSDK
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

extension CHSesame2 {
    
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
        }
    }
    
    func lockColor() -> UIColor {
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
        }
    }
    
    public func currentStatusImage() -> String {
    //    L.d("uiState",uiState.description())
        switch deviceStatus {

        case .noBleSignal:
            return "noBleSignal"
        case .receivedBle:
            return "receivedBle"
        case .bleConnecting:
            return "receivedBle"

        case .waitingGatt:
            return "waitingGatt"

        case .bleLogining:
            return "bleLogining"

        case .readyToRegister:
            return "bleLogining"
        case .locked:
            return "locked"

        case .unlocked:
            return "unlocked"

        case .moved:
            return "unlocked"

        case .noSettings:
            return "noSettings"
        case .reset:
            return "noBleSignal"
        case .registering:
            return "bleLogining"
        case .dfumode:
            return "bleLogining"
        }
    }
    
    func batteryImage() -> String {
        guard let batteryPercentage = mechStatus?.getBatteryPrecentage() else {
            return "bt0"
        }
        return batteryPercentage < 20 ? "bt0" : batteryPercentage < 50 ? "bt50" : "bt100"
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
