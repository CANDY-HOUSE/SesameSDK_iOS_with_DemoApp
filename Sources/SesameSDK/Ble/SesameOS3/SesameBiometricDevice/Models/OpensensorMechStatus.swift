//
//  OpensensorMechStatus.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/7.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
struct OpensensorMechStatus: CHSesameProtocolMechStatus {
    var battery: CShort? // 第一與第二個byte
    var data: Data
    var lightLoadBatteryVoltage: CShort?
    var heavyLoadBatteryVoltage: CShort?
    
    func getBatteryVoltage() -> Float {
        if let battery = battery {
            return Float(battery) * 2.0 / 1000.0
        }
        if let lightLoadVoltage = lightLoadBatteryVoltage {
            return Float(lightLoadVoltage) * 2.0 / 1000.0
        }
        return 6.0
    }
    
    func getBatteryPrecentage() -> Int { // [CHDeviceProtocol]共用電量計算曲線
        let voltage = getBatteryVoltage()
        let blocks: [Float] = [5.820, 5.810, 5.755, 5.735, 5.665, 5.620, 5.585, 5.556, 5.550, 5.530, 5.450, 5.400, 5.320, 5.280, 5.225, 5.150]
        let mapping: [Float] = [100.0, 95.0, 90.0, 85.0, 80.0, 70.0, 60.0, 50.0, 40.0, 32.0, 21.0, 13.0, 10.0, 7.0, 3.0, 0.0]
        if voltage >= blocks[0] {
            return Int(mapping[0])
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

    static func fromData(_ buf: OpenSensorData) -> OpensensorMechStatus? {
        let data = try! JSONEncoder().encode(buf)
        return OpensensorMechStatus(battery: buf.Battery, data: data, lightLoadBatteryVoltage: buf.lightLoadBatteryVoltage_mV, heavyLoadBatteryVoltage: buf.heavyLoadBatteryVoltage_mV)
    }
}
