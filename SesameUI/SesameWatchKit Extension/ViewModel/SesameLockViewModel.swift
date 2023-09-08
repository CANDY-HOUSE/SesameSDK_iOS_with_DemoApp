//
//  SesameCellViewModel.swift
//  SesameWatchKit Extension
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import CoreBluetooth
import SesameWatchKitSDK
import SwiftUI
import Combine

class SesameLockViewModel: ObservableObject {

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
    
    var lockTapped: (() -> Void)!
    private var timer: Timer?
    var device: CHDevice!

    init(device: CHDevice) {
        L.d("⌚️ init",device.productModel.deviceModel().description)

        self.display = device.deviceName
        self.device = device
        self.device.delegate = self
        if self.device.deviceId == device.deviceId, device.deviceStatus == .receivedBle() {
            device.connect() {_ in}
        }
        configure(sesame5: device)

        self.lockTapped = {
            (device as? CHSesame5)?.toggle { _ in }
            (device as? CHSesame2)?.toggle { _ in }
            (device as? CHSesameBot)?.click { _ in }
            (device as? CHSesameBike)?.unlock { _ in }
            (device as? CHSesameBike2)?.unlock { _ in }
        }
        executeOnMainThread {   self.startTimer(device) }
    }
    
    func startTimer(_ device: CHDevice) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            L.d("getSesameLockStatus")
            (device as? CHSesameLock)?.getSesameLockStatus { _ in }
        })
    }
    
    // MARK: - Private methods
    private func configure(sesame5: CHDevice) {
        imageName = sesame5.currentStatusImage()
        lockColor = sesame5.lockColor()
        batteryImage = "icn-battery"
        batteryIndicatorWidth = sesame5.batteryIndicatorWidth()
        wifiStatusImage = device.wifiImageStr()
        bluetoothImage = device.bluetoothImageStr()

        guard let mechStatus = sesame5.mechStatus else {
            return
        }
        batteryIndicatorColor =  mechStatus.getBatteryPrecentage() < 15 ?  Color(UIColor.lockRed):  Color(UIColor.sesame2Green)
        batteryPercentage = "\(mechStatus.getBatteryPrecentage())%"

        if (sesame5.productModel == .sesame5 || sesame5.productModel == .sesame5Pro){
            let toRadians = reverseDegree(angle: Int16(mechStatus.position))
            radians = CGFloat(toRadians)
        }else{
            let toRadians = angle2degree(angle: Int16(mechStatus.position))
            radians = CGFloat(toRadians)
        }
    }
    

    deinit {
        L.d("⌚️ deinit",device.productModel.deviceModel().description)
        self.timer?.invalidate()
    }
}

extension SesameLockViewModel: CHDeviceStatusDelegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        L.d("⌚️ onBleDeviceStatusChanged",device.productModel.deviceModel(),device.deviceStatus.description)
        if self.device.deviceId == device.deviceId, status == .receivedBle() {device.connect() {_ in}}
        executeOnMainThread {
            self.configure(sesame5: device)
        }
    }
    public func onMechStatus(device: CHDevice ) {
        L.d("⌚️ CHSesame5 onMechStatus")
        executeOnMainThread {
            self.configure(sesame5: device)
        }
    }
}
