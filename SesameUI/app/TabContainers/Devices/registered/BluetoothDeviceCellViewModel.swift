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
    func enterTestModeTapped(sesame2: CHSesame2)
}

public final class BluetoothDeviceCellViewModel: ViewModel, LockHaptic {
    public var statusUpdated: ViewStatusHandler?
    
    var delegate: BluetoothDeviceCellViewModelDelegate?
    var sesame2: CHSesame2
    var lockIntention: ((CHSesame2Intention) -> Void)?
    
    public init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
        sesame2.connect(){res in }
        sesame2.delegate = self
    }

    public var sesame2Name: String {
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        return device?.name ?? sesame2.deviceId!.uuidString
    }
    
    public var sesame2DeviceStatus: String {
        if CHConfiguration.shared.isDebugModeEnabled() {
            return sesame2.deviceStatus.description()
        } else {
            return ""
        }
    }
    
    public var sesame2ShadowStatus: String {
        if CHConfiguration.shared.isDebugModeEnabled() {
            return sesame2.deviceShadowStatus?.description() ?? ""
        } else {
            return ""
        }
    }
    
    public var isHideOwnerNameLabel: Bool {
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        return sesame2.deviceId.uuidString == device?.name
    }
    
    public var isShowContent: Bool {
        sesame2.deviceStatus.loginStatus() == .unlogined
    }
    
    public var lockColor: UIColor {
        sesame2.lockColor()
    }
    
    public var isInLockRange: Bool? {
        sesame2.mechStatus?.isInLockRange
    }
    
    public func sesame2LockTapped() {
        toggleWithHaptic(sesame2: sesame2) {}
    }
    
    public func sesame2LockImage() -> String {
        sesame2.currentStatusImage()
    }
    
    func powerPercentate() -> String {
        guard let powPercent = sesame2.mechStatus?.getBatteryPrecentage() else {
            return ""
        }
        return "\(powPercent) %"
    }
    
    public func batteryImage() -> String {
        return sesame2.batteryImage()
    }
    
    public func currentDegree() -> Float? {
        guard let status = sesame2.mechStatus else {
            return nil
        }
        return angle2degree(angle: status.position)
    }
    
    deinit {
//        L.d("BluetoothDeviceCellViewModel")
    }
}

extension BluetoothDeviceCellViewModel: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
//        L.d("status",status.description())
        if status == .receivedBle {
            sesame2.connect(){_ in}
        }
        statusUpdated?(.update(nil))
    }
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        lockIntention?(device.intention)
        statusUpdated?(.update(nil))
    }
}

// MARK: - Test mode
extension BluetoothDeviceCellViewModel {
    var isHideTestButton: Bool {
        !CHConfiguration.shared.isDebugModeEnabled()
    }
    
    public func enterTestModeTapped() {
        delegate?.enterTestModeTapped(sesame2: sesame2)
    }
}
