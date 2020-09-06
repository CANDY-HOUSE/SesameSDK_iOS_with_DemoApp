//
//  DeviceCell.swift
//  locker
//
//  Created by tse on 2019/10/15.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import CoreBluetooth

private enum Constant {
    static let resourceBundle = Bundle(for: DeviceCell.self)
}

private extension UIImage {
    static func CHUIImage(named: String) -> UIImage? {
        UIImage(named: named, in: Constant.resourceBundle, compatibleWith: nil)
    }
}

public class DeviceCell: UITableViewCell, LockHaptic {
    
    @IBOutlet weak var battery: UIImageView!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel!
    @IBOutlet weak var shadowStatusLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var lock: UIButton!
    var lockIntention: ((CHSesame2Intention) -> Void)?
    
    @IBAction func togle(_ sender: Any) {
//        sesame2?.toggleWithHaptic(interval: 1.5)
        toggleWithHaptic(sesame2: sesame2!) {
            
        }
    }
    @IBOutlet weak var circle: Sesame2Circle!
    public var sesame2: CHSesame2?{
        didSet{
            sesame2?.delegate = self
            sesame2?.connect{res in}
            updateUI()
            
            let device = Sesame2Store.shared.getOrCreatePropertyOfSesame2(sesame2!)
            deviceName.text = device.name ?? device.deviceID!.uuidString
            
            if #available(iOSApplicationExtension 13.0, *) {
                deviceStatusLabel.textColor = UIColor.placeholderText
                shadowStatusLabel.textColor = UIColor.placeholderText
                power.textColor = UIColor.placeholderText
            }
        }
    }
    
    func updateUI()  {
        executeOnMainThread {
            var currentDegree: Float = 0.0
            if let status = self.sesame2?.mechStatus {
                currentDegree = angle2degree(angle: status.position)
            }
            if CHConfiguration.shared.isDebugModeEnabled() {
                self.deviceStatusLabel.text = self.sesame2?.deviceStatus.description()
                self.shadowStatusLabel.text = self.sesame2?.deviceShadowStatus?.description() ?? ""
            } else {
                self.deviceStatusLabel.text = ""
                self.shadowStatusLabel.text = ""
            }
            self.circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                  lockColor: self.sesame2!.lockColor())
            let statusIMG = UIImage.CHUIImage(named: self.sesame2!.currentStatusImage())
            self.lock.setBackgroundImage(statusIMG, for: .normal)
            if let powPercent = self.sesame2?.mechStatus?.getBatteryPrecentage() {
                self.power.text = "\(powPercent)%"
            } else {
                self.power.text = ""
            }
            
            self.battery.image = UIImage.CHUIImage(named: self.sesame2!.batteryImage())
        }
        
    }
}

extension DeviceCell: CHSesame2Delegate{

    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if device.deviceId == sesame2?.deviceId,
            status == .receivedBle {
            device.connect(){res in}
        }
        updateUI()
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        lockIntention?(device.intention)
        updateUI()
    }
}
