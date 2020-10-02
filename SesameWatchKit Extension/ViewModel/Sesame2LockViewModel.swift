//
//  SesameCellViewModel.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import CoreBluetooth
import SesameWatchKitSDK
import SwiftUI
import Combine

class Sesame2LockViewModel: ObservableObject {
    
    @Published var display = ""
    @Published var imageName = ""
    @Published var batteryPercentage = ""
    @Published var cellTapped: (() -> Void)!
    @Published var radians: CGFloat = 0
    @Published var moonColor: UIColor = UIColor.yellow
    @Published var batteryImage = ""
    
    var uuid: UUID?
    private var device: CHSesame2
    private var disposables = [AnyCancellable]()
    
    init(device: CHSesame2) {
        self.uuid = device.deviceId
        self.device = device
        let display = Sesame2Store.shared.getSesame2Property(device)?.name
        self.display = display ?? device.deviceId.uuidString
        self.device.delegate = self
        
        self.device.connect { _ in
            
        }
        
        self.cellTapped = { [weak self] in
            self?.device.toggle { _ in
                
            }
        }
        
        // Initial view
        setContentBy(device: device)
    }
    
    // MARK: - Private methods
    private func setContentBy(device: CHSesame2) {
        imageName = device.currentStatusImage()
        moonColor = device.lockColor()
        batteryImage = device.batteryImage()
        guard let mechStatus = device.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
        let toRadians = angle2degree(angle: Int16(mechStatus.position))
        radians = CGFloat(toRadians)
    }
}

extension Sesame2LockViewModel: CHSesame2Delegate {
    func onBleDeviceStatusChanged(device: CHSesame2,
                                  status: CHSesame2Status,
                                  shadowStatus: CHSesame2ShadowStatus?) {
        if device.deviceId == self.device.deviceId, status == .receivedBle {
            device.connect() {res in}
        }
        executeOnMainThread {
            self.setContentBy(device: device)
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.setContentBy(device: device)
        }
    }
}
