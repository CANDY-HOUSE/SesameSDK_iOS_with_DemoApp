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
        let blocks: [Float] = [5.85, 5.82, 5.79, 5.76, 5.73, 5.70, 5.65, 5.60, 5.55, 5.50, 5.40, 5.20, 5.10, 5.0, 4.8, 4.6].map { $0 - 0.3 }//放水讓用戶開心,電力曲線整體下降0.3V, 用更低的電壓對應更高的電量百分比
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
