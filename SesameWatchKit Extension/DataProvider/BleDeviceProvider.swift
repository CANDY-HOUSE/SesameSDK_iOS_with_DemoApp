//
//  BleDeviceProvider.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

final class BleDeviceProvider: Provider, CHSesame2Delegate {
    var subjectPublisher = PassthroughSubject<BleDeviceSubject, Error>()
    private var disposables = [AnyCancellable]()
    
    private var device: CHSesame2
    
    init(device: CHSesame2) {
        self.device = device
    }
    
    func connect() {
        device.connect(){res in}
        device.delegate = self
    }
    
    func onBleDeviceStatusChanged(device: CHSesame2,
                                  status: CHSesame2Status) {
        if device.deviceId == self.device.deviceId, status == .receivedBle {
            device.connect(){res in}
            self.device = device
        }
        let subject = BleDeviceSubject(request: .init(device))
        subjectPublisher.send(subject)
        subject.connect()
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        let subject = BleDeviceSubject(request: .init(device))
        subjectPublisher.send(subject)
        subject.connect()
    }
    
    deinit {
        device.disconnect { _ in
            
        }
    }
}
