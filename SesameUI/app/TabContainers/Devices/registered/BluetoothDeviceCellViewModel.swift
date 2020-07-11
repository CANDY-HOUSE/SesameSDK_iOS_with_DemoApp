//
//  BluetoothDeviceCellViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import CoreBluetooth
import UIKit.UIColor

public protocol BluetoothDeviceCellViewModelDelegate {
    func enterTestModeTapped(ssm: CHSesame2)
}

public final class BluetoothDeviceCellViewModel: ViewModel {

    public var statusUpdated: ViewStatusHandler?
    
    var delegate: BluetoothDeviceCellViewModelDelegate?
    var ssm: CHSesame2
    
    public init(ssm: CHSesame2) {
        self.ssm = ssm
        ssm.connect(){res in }
        ssm.delegate = self
    }

    public var name: String {
        let device = SSMStore.shared.getPropertyForDevice(ssm)
        return device.name ?? device.deviceID!.uuidString
    }
    
    public var ownerNameLabel: String {
        ""
    }
    
    public var isHideOwnerNameLabel: Bool {
        let device = SSMStore.shared.getPropertyForDevice(ssm)
        return ssm.deviceId.uuidString == device.name
    }
    
    public var isShowContent: Bool {
        ssm.deviceStatus.loginStatus() == .unlogin
    }
    
    public var lockColor: UIColor {
        ssm.lockColor()
    }
    
    public var isInLockRange: Bool? {
        ssm.mechStatus?.isInLockRange()
    }
    
    public func toggleTapped() {
        ssm.toggleWithHaptic(interval: 1.5)
    }
    
    public func lockBackgroundImage() -> String {
        ssm.currentStatusImage()
    }
    
    func powerPercentate() -> String {
        let powPercent = ssm.batteryPrecentage() ?? 0
        return "\(powPercent)"
    }
    
    public func batteryImage() -> String {
        return ssm.batteryImage() ?? "bt0"
    }
    
    public func currentDegree() -> Float? {
        guard let status = ssm.mechStatus,
            let currentAngle = status.getPosition() else {
            return nil
        }
        return angle2degree(angle: Int16(currentAngle))
    }
    
    deinit {
//        L.d("BluetoothDeviceCellViewModel")
    }
}

extension BluetoothDeviceCellViewModel: CHSesameDelegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesameStatus) {
        if device.deviceId == ssm.deviceId,
            status == .receiveBle {
            ssm.connect(){_ in}
        }
        statusUpdated?(.received)
    }
}

// MARK: - Test mode
extension BluetoothDeviceCellViewModel {
    var isHideTestButton: Bool {
        !UserDefaults.standard.bool(forKey: "testMode")
    }
    
    public func enterTestModeTapped() {
        delegate?.enterTestModeTapped(ssm: ssm)
    }
}
