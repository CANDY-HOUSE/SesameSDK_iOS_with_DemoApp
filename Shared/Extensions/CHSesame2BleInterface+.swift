//
//  CHSesameBleInterface+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/4.
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

extension CHSesame2 {
    
    func toggleWithHaptic(interval: TimeInterval) {
        #if os(iOS)
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
        
        toggle { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: {
                
                let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
                notificationFeedbackGenerator.prepare()
                
                switch result {
                case .success(let sdsdsd):
                    L.d("sdsdsd" , sdsdsd,sdsdsd.data)

                    notificationFeedbackGenerator.notificationOccurred(.success)
                case .failure(let error):
                    L.d("error",error)
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
            })
        }
        #elseif os(watchOS)
        if deviceStatus == .locked {
            WKInterfaceDevice.current().play(.start)
        } else if deviceStatus == .unlocked {
            WKInterfaceDevice.current().play(.stop)
        }
        
        toggle { _ in

        }
        #endif
    }
    
    public func localizedDescription() -> String {
        switch deviceStatus {
        case .reset:
            return "co.candyhouse.sesame-sdk-test-app.reset".localized
        case .noSignal:
            return "co.candyhouse.sesame-sdk-test-app.noSignal".localized
        case .receiveBle:
            return "co.candyhouse.sesame-sdk-test-app.receiveBle".localized
        case .connecting:
            return "co.candyhouse.sesame-sdk-test-app.connecting".localized
        case .waitgatt:
            return "co.candyhouse.sesame-sdk-test-app.waitgatt".localized
        case .logining:
            return "co.candyhouse.sesame-sdk-test-app.logining".localized
        case .readytoRegister:
            return "co.candyhouse.sesame-sdk-test-app.readytoRegister".localized
        case .locked:
            return "co.candyhouse.sesame-sdk-test-app.locked".localized
        case .unlocked:
            return "co.candyhouse.sesame-sdk-test-app.unlocked".localized
        case .nosetting:
            return "co.candyhouse.sesame-sdk-test-app.nosetting".localized
        case .moved:
            return "co.candyhouse.sesame-sdk-test-app.moved".localized
        case .registing:
            return "co.candyhouse.sesame-sdk-test-app.registing".localized
        case .dfumode:
            return "dfumode"
        }
    }
    
    func lockColor() -> UIColor {
        switch deviceStatus {
        case .reset:
            return .lockGray
        case .noSignal:
            return .lockGray
        case .receiveBle:
            return .lockYellow
        case .connecting:
            return .lockYellow
        case .waitgatt:
            return .lockYellow
        case .logining:
            return .lockYellow
        case .readytoRegister:
            return .lockYellow
        case .locked:
            return .lockRed
        case .unlocked:
            return .lockGreen
        case .moved:
            return .lockGreen
        case .nosetting:
            return .lockGray
        case .registing:
            return .lockGray
        case .dfumode:
            return .lockGray
        }
    }
    
    public func currentStatusImage() -> String {
    //    L.d("uiState",uiState.description())
        switch deviceStatus {

        case .noSignal:
            return "l-no"
        case .receiveBle:
            return "receiveBle"
        case .connecting:
            return "receiveBle"

        case .waitgatt:
            return "waitgatt"

        case .logining:
            return "logining"

        case .readytoRegister:
            return "logining"
        case .locked:
            return "img-lock"

        case .unlocked:
            return "img-unlock"

        case .moved:
            return "img-unlock"

        case .nosetting:
            return "l-set"
        case .reset:
            return "l-no"
        case .registing:
            return "logining"
        case .dfumode:
            return "logining"
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
