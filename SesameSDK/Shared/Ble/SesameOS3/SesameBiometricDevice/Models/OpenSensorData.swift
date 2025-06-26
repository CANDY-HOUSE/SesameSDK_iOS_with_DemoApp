//
//  OpenSensorData.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public struct OpenSensorData: Codable {
    public var Status: String
    public var TimeStamp: Int
    var Battery: CShort?
    var lightLoadBatteryVoltage_mV: CShort?
    var heavyLoadBatteryVoltage_mV: CShort?
}
