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

    lazy var isCurrentSesameLock = {
        return [
            CHProductModel.sesame2,
            CHProductModel.sesame4,
            CHProductModel.sesame5,
            CHProductModel.sesame5Pro,
            CHProductModel.sesame5US,
            CHProductModel.sesame6Pro,
            CHProductModel.sesame6ProSLiDingDoor,
            CHProductModel.sesameMiwa
        ].contains(device.productModel)
    }()

    init(device: CHDevice?) {
        guard let device = device else { return } /// 防止 nil时 崩溃
        self.display = device.deviceName
        self.device = device
        self.device.delegate = self
        if self.device.deviceId == device.deviceId, device.deviceStatus == .receivedBle() {
            device.connect() {_ in}
        }
        configure(sesame5: device)

        self.lockTapped = { [weak self] in
            guard let self = self else { return }
            (self.device as? CHSesame5)?.toggle(historytag: self.device.hisTag) { _ in }
            (self.device as? CHSesame2)?.toggle { _ in }
            (self.device as? CHSesameBot)?.click { _ in }
            (self.device as? CHSesameBike)?.unlock { _ in }
            (self.device as? CHSesameBike2)?.unlock { _ in }
            (self.device as? CHSesameBot2)?.click(index: nil, result: { _ in })
        }
        executeOnMainThread {   self.startTimer(device) }
    }
    
    func startTimer(_ device: CHDevice) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            L.d("getSesameLockStatus")
            (device as? CHSesameLock)?.getSesameLockStatus { _ in }
        })
    }
    
    func prepareDestory() {
        self.timer?.invalidate()
        self.timer = nil
        self.device?.delegate = nil
        self.device?.disconnect(result: { _ in })
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

        if (sesame5.productModel == .sesame5 || sesame5.productModel == .sesame5Pro || sesame5.productModel == .sesame5US || sesame5.productModel == .sesame6Pro || sesame5.productModel == .sesame6ProSLiDingDoor || sesame5.productModel == .sesameMiwa){
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
