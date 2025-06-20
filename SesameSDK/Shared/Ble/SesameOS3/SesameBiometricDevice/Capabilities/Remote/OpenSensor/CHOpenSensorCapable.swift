//
//  CHOpenSensorCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHOpenSensorCapable: CHDevice {
    func goIoTWithOpenSensor()
    func getLatestState(result: @escaping (OpenSensorData?) -> Void)
}
