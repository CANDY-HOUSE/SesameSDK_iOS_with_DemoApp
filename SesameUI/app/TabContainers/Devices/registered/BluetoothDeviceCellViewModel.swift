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
    func enterTestModeTapped(ssm: CHSesameBleInterface)
}

public final class BluetoothDeviceCellViewModel: ViewModel {

    public var statusUpdated: ViewStatusHandler?
    
    var delegate: BluetoothDeviceCellViewModelDelegate?
    private let id = UUID()
    var ssm: CHSesameBleInterface
    
    public init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
//        ssm.updateObserver(self, forKey: id.uuidString)
//        ssm.updateObserver(self)
        ssm.connect()
        ssm.delegate = self
    }
    
//    public func viewWillAppear() {
//        ssm.delegate = self
//    }
    
    public var name: String {
//        let storage = AnyObjectStore<SSMProperty>()
//        return storage.valueForKey(ssm.deviceId!.uuidString)?.ssmName ?? ssm.deviceId!.uuidString
        if let device = SSMStore.shared.getPropertyForDevice(ssm) {
            return device.name ?? device.uuid!.uuidString
        } else {
            return ssm.deviceId.uuidString
        }
    }
    
    public var ownerNameLabel: String {
//        ssm.deviceId!.uuidString
        ""
    }
    
    public var isHideOwnerNameLabel: Bool {
        guard let device = SSMStore.shared.getPropertyForDevice(ssm) else {
            return true
        }
        return ssm.deviceId.uuidString == device.name
    }
    
    public var isShowContent: Bool {
        ssm.deviceStatus.loginStatus() == .unlogin
    }
    
    public var lockColor: UIColor {
        ssm.lockColor()
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
    
    public var isInLockRange: Bool? {
        ssm.mechStatus?.isInLockRange()
    }
    
    deinit {
//        ssm.removeObserver(forKey: id.uuidString)
    }
}

extension BluetoothDeviceCellViewModel: CHSesameBleDeviceDelegate {
    public func onBleDeviceStatusChanged(device: CHSesameBleInterface, status: CHDeviceStatus) {
        if device.deviceId == ssm.deviceId,
            status == .receiveBle {
            ssm.connect()
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
