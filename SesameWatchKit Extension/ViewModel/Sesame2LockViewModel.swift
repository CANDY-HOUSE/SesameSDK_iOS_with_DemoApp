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
    
    enum DeviceType {
        case sesame2
        case sesameBot
        case bikeLock
    }
    
    @Published var display = ""
    @Published var imageName = ""
    @Published var batteryPercentage = ""
    @Published var radians: CGFloat = 0
    @Published var lockColor: UIColor = UIColor.yellow
    @Published var batteryImage = ""
    @Published var batteryIndicatorWidth: CGFloat = 0
    @Published var batteryIndicatorColor = Color(UIColor.sesame2Green)
    @Published var bluetoothImage = "bluetooth_gray"
    @Published var wifiStatusImage = "wifi_gray"
    
    var deviceType: DeviceType!
    var lockTapped: (() -> Void)!
    private var timer: Timer?
    private var device: CHDevice!
    
    init(device: CHDevice) {
        self.display = device.deviceName
        self.device = device

        if let sesameLock = device as? CHSesame2 {
            self.deviceType = .sesame2
            sesameLock.delegate = self
            self.lockTapped = {
                sesameLock.toggle { _ in }
            }
            configure(sesame2: sesameLock)
        } else if let sesameLock = device as? CHSesameBot {
            sesameLock.delegate = self
            self.lockTapped = {
                sesameLock.click { _ in }
            }
            self.deviceType = .sesameBot
            configure(sesameBot: sesameLock)
        } else if let sesameLock = device as? CHSesameBike {
            sesameLock.delegate = self
            self.lockTapped = {
                sesameLock.unlock { _ in }
            }
            self.deviceType = .bikeLock
            configure(bikeLock: sesameLock)
        }
        (device as? CHSesameLock)?.getSesameLockStatus { _ in
            executeOnMainThread {
                self.startTimer(device)
            }
        }
    }
    
    func startTimer(_ device: CHDevice) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { _ in
            if device.deviceStatus.loginStatus == .unlogined {
                (device as? CHSesameLock)?.getSesameLockStatus { _ in }
            }
        })
    }
    
    func updateStatusImage() {
        if device.wifiColor() == .lockGray {
            wifiStatusImage = "wifi_gray"
        } else if device.wifiColor() == .lockYellow {
            wifiStatusImage = "wifi_yellow"
        } else if device.wifiColor() == .sesame2Green {
            wifiStatusImage = "wifi_green"
        } else if device.wifiColor() == .lockRed {
            wifiStatusImage = "wifi_red"
        }
        if device.bluetoothColor() == .lockGray {
            bluetoothImage = "bluetooth_gray"
        } else if device.bluetoothColor() == .lockYellow {
            bluetoothImage = "bluetooth_yellow"
        } else if device.bluetoothColor() == .sesame2Green {
            bluetoothImage = "bluetooth_green"
        } else if device.bluetoothColor() == .lockRed {
            bluetoothImage = "bluetooth_red"
        }
    }
    
    // MARK: - Private methods
    private func configure(sesame2: CHSesame2) {
        imageName = sesame2.currentStatusImage()
        lockColor = sesame2.lockColor()
        batteryImage = "icn-battery"
        batteryIndicatorWidth = sesame2.batteryIndicatorWidth()
        batteryIndicatorColor = Color(sesame2.batteryIndicatorColor())
        updateStatusImage()
        guard let mechStatus = sesame2.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
        let toRadians = angle2degree(angle: Int16(mechStatus.position))
        radians = CGFloat(toRadians)
    }
    
    private func configure(sesameBot: CHSesameBot) {
        imageName = sesameBot.currentStatusImage()
        lockColor = sesameBot.lockColor()
        batteryImage = "icn-battery"
        batteryIndicatorWidth = sesameBot.batteryIndicatorWidth()
        batteryIndicatorColor = Color(sesameBot.batteryIndicatorColor())
        updateStatusImage()
        guard let mechStatus = sesameBot.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
    }
    
    private func configure(bikeLock: CHSesameBike) {
        imageName = bikeLock.currentStatusImage()
        lockColor = bikeLock.lockColor()
        batteryImage = "icn-battery"
        batteryIndicatorWidth = bikeLock.batteryIndicatorWidth()
        batteryIndicatorColor = Color(bikeLock.batteryIndicatorColor())
        updateStatusImage()
        guard let mechStatus = bikeLock.mechStatus else {
            return
        }
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"
    }
    
    deinit {
        self.timer?.invalidate()
    }
}

extension Sesame2LockViewModel: CHSesame2StatusDelegate {
    func onBleDeviceStatusChanged(device: CHSesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if self.device.deviceId == device.deviceId, status == .receivedBle() {
            device.connect() {res in}
        }
        executeOnMainThread {
            if let sesameLock = device as? CHSesame2 {
                self.configure(sesame2: sesameLock)
            } else if let sesameLock = device as? CHSesameBot {
                self.configure(sesameBot: sesameLock)
            } else if let sesameLock = device as? CHSesameBike {
                self.configure(bikeLock: sesameLock)
            }
        }
    }
}

extension Sesame2LockViewModel: CHSesame2Delegate {
    public func onMechStatusChanged(device: CHSesame2, status: CHSesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.configure(sesame2: device)
        }
    }
}

extension Sesame2LockViewModel: CHSesameBotDelegate {
    public func onMechStatusChanged(device: CHSesameBot, status: CHSesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.configure(sesameBot: device)
        }
    }
}

extension Sesame2LockViewModel: CHSesameBikeDelegate {
    public func onMechStatusChanged(device: CHSesameBike, status: CHSesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.configure(bikeLock: device)
        }
    }
}
