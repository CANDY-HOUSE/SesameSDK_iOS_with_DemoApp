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
//    private var bleProvider: BleDeviceProvider!
    
    init(device: CHSesame2) {
        // Initial properties
        self.uuid = device.deviceId
        self.device = device
        self.device.connect(){res in}
        self.device.delegate = self
//        self.bleProvider = BleDeviceProvider(device: device)
//        // Binding or configure
//        self.bleProvider
//            .subjectPublisher
//            .map { $0.result }
//            .switchToLatest()
//            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
//            .sink(receiveCompletion: { complete in
//                switch complete {
//                case .finished:
//                    break
//                case .failure(let error):
//                    L.d(error)
//                }
//            }) { [weak self] device in
//                guard let strongSelf = self else { return }
//                strongSelf.device = device
//                strongSelf.setContentBy(device: device)
//        }
//        .store(in: &disposables)
//
//        self.bleProvider.connect()
        
        self.cellTapped = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let device = strongSelf.device
            device.toggleWithHaptic(interval: 1.5)
        }
        
//        NotificationCenter.default.publisher(for: .ApplicationDidBecomeActive)
//            .debounce(for: 1.0, scheduler: DispatchQueue.main)
//            .receive(on: DispatchQueue.main)
//            .sink { _ in
//                self.setContentBy(device: self.device)
//        }
//        .store(in: &self.disposables)
        
        // Initial view
        setContentBy(device: device)
        
        guard let status = device.mechStatus
            else {
            return
        }
        let degreeFrom = angle2degree(angle: Int16(status.position))
        radians = CGFloat(degreeFrom.degreesToRadians)
    }
    
    // MARK: - Private methods
    private func setContentBy(device: CHSesame2) {
        display = Sesame2Store.shared.getPropertyForDevice(device).name ?? device.deviceId.uuidString
        imageName = device.currentStatusImage()
        moonColor = device.lockColor()
        batteryImage = device.batteryImage()
        guard let mechStatus = device.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
    }
}

extension Sesame2LockViewModel: CHSesame2Delegate {
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if device.deviceId == self.device.deviceId,
            status == .receiveBle {
            self.device = device
            self.device.connect(){res in}
            self.device.delegate = self
        }
        setContentBy(device: self.device)
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        guard let mechStatus = device.mechStatus else {
            return
        }
        let toRadians = angle2degree(angle: Int16(mechStatus.position))
        radians = CGFloat(toRadians)
    }
    
    private func angle2degree(angle: Int16) -> Float {
        var degree = Float(angle % 1024)
        degree = degree * 360 / 1024
        if degree > 0 {
            degree = 360 - degree
        } else {
            degree = abs(degree)
        }
        return degree
    }
}
