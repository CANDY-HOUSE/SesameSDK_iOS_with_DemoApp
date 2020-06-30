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

extension CHSesameBleInterface {
    
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
                case .success(_):
                    notificationFeedbackGenerator.notificationOccurred(.success)
                case .failure(_):
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
        
        toggle { result in
//            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: {
//                switch result {
//                case .success(_):
//                    WKInterfaceDevice.current().play(.success)
//                case .failure(_):
//                    WKInterfaceDevice.current().play(.failure)
//                }
//            })
        }
        #endif
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
        }
    }
    
    func batteryPrecentage() -> Int? {
        
        guard let voltage = mechStatus?.getBatteryVoltage() else {
            return nil
        }
        
        let blocks:[Float] = [6.0,5.8,5.7,5.6,5.4,5.2,5.1,5.0,4.8,4.6]
        let mapping:[Float] = [100.0,50.0,40.0,32.0,21.0,13.0,10.0,7.0,3.0,0.0]
        if voltage >= blocks[0] {
            return Int((voltage-blocks[0])*200/blocks[0] + 100)
        }
        if voltage <= blocks[blocks.count-1] {
            return Int(mapping[mapping.count-1])
        }

        for i in 0..<blocks.count-1 {
            let upper: CFloat = blocks[i]
            let lower: CFloat = blocks[i+1]
            if voltage <= upper && voltage > lower {
                let value: CFloat = (voltage-lower)/(upper-lower)
                let max = mapping[i]
                let min = mapping[i+1]
                return Int((max-min)*value+min)
            }
        }
        return 0
    }
    
    func batteryImage() -> String? {
        guard let batteryPercentage = batteryPrecentage() else {
            return nil
        }
        return batteryPercentage < 20 ? "bt0" : batteryPercentage < 50 ? "bt50" : "bt100"
    }
}
