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

class Sesame2LockViewModel: ObservableObject, LockHaptic {
    var lockIntention: ((CHSesame2Intention) -> Void)?
    
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
    private var bleProvider: BleDeviceProvider!
    
    init(device: CHSesame2) {
        // Initial properties
        self.uuid = device.deviceId
        self.device = device
        self.bleProvider = BleDeviceProvider(device: device)
        let display = Sesame2Store.shared.getSesame2Property(device)?.name
//        L.d("⌚️ Sesame2Store.shared.getPropertyOfSesame2(device).name", display)
        self.display = display ?? device.deviceId.uuidString
        // Binding or configure
        self.bleProvider
            .subjectPublisher
            .map { $0.result }
            .switchToLatest()
//            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { complete in
                switch complete {
                case .finished:
                    break
                case .failure(let error):
                    L.d(error)
                }
            }) { [weak self] device in
                guard let strongSelf = self else { return }
                strongSelf.device = device
                strongSelf.setContentBy(device: device)
        }
        .store(in: &disposables)

        self.bleProvider.connect()
        
        self.cellTapped = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let device = strongSelf.device
            self?.toggleWithHaptic(sesame2: device, {
                
            })
        }
        
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
        imageName = device.currentStatusImage()
        moonColor = device.lockColor()
        batteryImage = device.batteryImage()
        guard let mechStatus = device.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
        let toRadians = angle2degree(angle: Int16(mechStatus.position))
        radians = CGFloat(toRadians)
        lockIntention?(device.intention)
    }
}
