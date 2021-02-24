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
    private enum Constant {
        enum Battery {
            static let battery0 = "bt0"
            static let battery50 = "bt50"
            static let battery100 = "bt100"
        }
        enum Lock {
            static let yellow = UIColor(rgb: 0xf9e074)
            static let red = UIColor(rgb: 0xcc4a44)
            static let green = UIColor.sesame2Green
            static let gray = UIColor(rgb: 0xe4e3e3)
        }
    }
    
    @Published var display = ""
    @Published var imageName = ""
    @Published var batteryPercentage = ""
    @Published var cellTapped: (() -> Void)!
    @Published var radians: CGFloat = 0
    @Published var moonColor: UIColor = UIColor.yellow
    @Published var batteryImage = Constant.Battery.battery0
    
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
        
        guard let status = device.mechStatus,
            let currentAngle = status.getPosition() else {
            return
        }
        let degreeFrom = angle2degree(angle: Int16(currentAngle))
        radians = CGFloat(degreeFrom.degreesToRadians)
    }
    
    // MARK: - Private methods
    private func setContentBy(device: CHSesame2) {
        display = Sesame2Store.shared.getPropertyForDevice(device).name ?? device.deviceId.uuidString
        imageName = deviceStatusImage(device.deviceStatus)
        let batteryPercentage = batteryPrecentage(voltage: device.mechStatus?.getBatteryVoltage() ?? 0)
        self.batteryPercentage = "\(batteryPercentage)%"
        batteryImage = batteryImageByPercentage(batteryPercentage)
        moonColor = moonColorByStatus(device.deviceStatus)
        
        guard let status = device.mechStatus,
            var currentAngle = status.getPosition() else {
                let toRadians = angle2degree(angle: Int16(0))
                radians = CGFloat(toRadians)
            return
        }
        
        currentAngle = currentAngle == 0 ? 5 : currentAngle
        
        let toRadians = angle2degree(angle: Int16(currentAngle))
        radians = CGFloat(toRadians)
    }
    
    private func batteryImageByPercentage(_ percentage: Int) -> String {
        percentage < 20 ? Constant.Battery.battery0 : percentage < 50 ? Constant.Battery.battery50 : Constant.Battery.battery100
    }
    
    private func moonColorByStatus(_ status: CHSesame2Status) -> UIColor {
        switch status {
        case .reset:
            return Constant.Lock.gray
        case .noSignal:
            return Constant.Lock.gray
        case .receiveBle:
            return Constant.Lock.yellow
        case .connecting:
            return Constant.Lock.yellow
        case .waitgatt:
            return Constant.Lock.yellow
        case .logining:
            return Constant.Lock.yellow
        case .readytoRegister:
            return Constant.Lock.yellow
        case .locked:
            return Constant.Lock.red
        case .unlocked:
            return Constant.Lock.green
        case .moved:
            return Constant.Lock.green
        case .nosetting:
            return Constant.Lock.gray
        }
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
    
    private func batteryPrecentage(voltage: Float) -> Int {
        let blocks: [Float] = [6.0, 5.8, 5.7, 5.6, 5.4, 5.2, 5.1, 5.0, 4.8, 4.6]
        let mapping: [Float] = [100.0, 50.0, 40.0, 32.0, 21.0, 13.0, 10.0, 7.0, 3.0, 0.0]
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
    
    private func deviceStatusImage(_ status: CHSesame2Status) -> String {
        switch status {
        case .reset:
            return "l-no"
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
        }
    }
}

<<<<<<< HEAD
extension Sesame2LockViewModel: CHSesame2Delegate {
=======
extension SesameLockViewModel: CHSesameDelegate {
>>>>>>> 04a8a7ed12c4014bd10a9158d3eec1c5f39732d4
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if device.deviceId == self.device.deviceId,
            status == .receiveBle {
            self.device = device
            self.device.connect(){res in}
            self.device.delegate = self
        }
        setContentBy(device: self.device)
    }
}
