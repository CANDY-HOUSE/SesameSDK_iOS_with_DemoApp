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

    static func fromData(_ buf: OpenSensorData) -> OpensensorMechStatus? {
        let data = try! JSONEncoder().encode(buf)
        return OpensensorMechStatus(battery: buf.Battery, data: data, lightLoadBatteryVoltage: buf.lightLoadBatteryVoltage_mV, heavyLoadBatteryVoltage: buf.heavyLoadBatteryVoltage_mV)
    }
}
