//
//  Sesame2ListCellController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class Sesame2ListCellController: Sesame2ListCellDelegate, CHSesame2Delegate {
    
    // MARK: - Data model
    var sesame2: CHSesame2
    
    // MARK: - UI component
    var cell: Sesame2ListCell? {
        didSet {
            cell?.delegate = self
            configureCell()
        }
    }
    var navigationController: UINavigationController
    
    init(cell: Sesame2ListCell? = nil, sesame2: CHSesame2, navigationController: UINavigationController) {
        self.cell = cell
        self.navigationController = navigationController
        self.sesame2 = sesame2
        self.cell?.delegate = self
        self.sesame2.delegate = self
        self.configureCell()
    }
    
    // MARK: - ListCellDelegate
    func sesame2CircleTapped(_ cell: Sesame2ListCell) {
        sesame2.toggle { _ in
            
        }
    }
    
    func debugModeTapped(_ cell: Sesame2ListCell) {
        guard let bluetoothSesameControlViewController = UIStoryboard.viewControllers.bluetoothSesameControlViewController else {
            return
        }
        bluetoothSesameControlViewController.sesame = sesame2
        navigationController.pushViewController(bluetoothSesameControlViewController, animated: true)
    }
    
    func configureCell() {
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        cell?.deviceNameLabel.text = device?.name ?? sesame2.deviceId!.uuidString
        cell?.sesame2AngleLabel.text = ""
        if CHConfiguration.shared.isDebugModeEnabled() {
            cell?.sesame2StatusLabel.text = sesame2.deviceStatus.description()
            cell?.sesame2ShadowStatusLabel.text = sesame2.deviceShadowStatus?.description()
        } else {
            cell?.sesame2StatusLabel.text = ""
            cell?.sesame2ShadowStatusLabel.text = ""
        }
        
        cell?.debugModeButton.isHidden = !CHConfiguration.shared.isDebugModeEnabled()
        cell?.sesame2CircleButton.setBackgroundImage(UIImage.CHUIImage(named: sesame2.currentStatusImage()), for: .normal)
        
        if let mechStatus = sesame2.mechStatus {
            let batteryPercentage = "\(mechStatus.getBatteryPrecentage()) %"
            let lockAngle = CGFloat(angle2degree(angle: mechStatus.position))
            cell?.batteryPercentageLabel.text = batteryPercentage
            cell?.updateSesameCircle(lockAngle: lockAngle, lockColor: sesame2.lockColor())
            
            if CHConfiguration.shared.isDebugModeEnabled() {
                cell?.sesame2AngleLabel.text = "\(mechStatus.position)"
            } else {
                cell?.sesame2AngleLabel.text = ""
            }
        }
        
        cell?.batteryImageView.image = UIImage.CHUIImage(named: sesame2.batteryImage())
    }
    
    // MARK: - CHSesame2Delegate
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle {
            device.connect(){_ in}
        }
        executeOnMainThread {
            self.configureCell()
        }
    }
    
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.configureCell()
        }
    }
}
