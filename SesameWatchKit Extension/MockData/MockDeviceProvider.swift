//
//  MockDeviceProvider.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/6.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

final class MockDeviceProvider: Provider {
    
    var subjectPublisher = PassthroughSubject<DeviceModelSubject, Error>()
    
    private var numberOfDevices: Int
    
    init(_ numberOfDevices: Int = 3) {
        self.numberOfDevices = numberOfDevices
    }
    
    func connect() {
        var devices = [MockBleDevice]()
        for _ in 0..<self.numberOfDevices {
            devices.append(MockBleDevice())
        }
        
        let deviceModelSubject = DeviceModelSubject(request: .init(devices))
        self.subjectPublisher.send(deviceModelSubject)
        deviceModelSubject.connect()
    }
}
