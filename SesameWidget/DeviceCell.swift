//
//  DeviceCell.swift
//  locker
//
//  Created by tse on 2019/10/15.
//  Copyright © 2019 Cerberus. All rights reserved.
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

public class DeviceCell: UITableViewCell {
    
    @IBOutlet weak var battery: UIImageView!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var ownerName: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var lock: UIButton!
    @IBAction func togle(_ sender: Any) {
        sesame2?.toggleWithHaptic(interval: 1.5)
    }
    @IBOutlet weak var circle: Sesame2Circle!
    public var sesame2: CHSesame2?{
        didSet{
            sesame2?.delegate = self
            sesame2?.connect{res in}
            
            updateUI()

//            ownerName.isHidden = true
            ownerName.text = sesame2?.deviceStatus.description()
            
            let device = Sesame2Store.shared.getPropertyForDevice(sesame2!)
            deviceName.text = device.name ?? device.deviceID!.uuidString
            
            if #available(iOSApplicationExtension 13.0, *) {
                ownerName.textColor = UIColor.placeholderText
                power.textColor = UIColor.placeholderText
            }
        }
    }
    
    func updateUI()  {
        var currentDegree: Float = 0.0
        if let status = sesame2?.mechStatus,
            let currentAngle = status.getPosition() {
            currentDegree = angle2degree(angle: Int16(currentAngle))
        }
        ownerName.text = sesame2?.deviceStatus.description()

        circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                         lockColor: sesame2!.lockColor())
        let statusIMG = UIImage.CHUIImage(named: sesame2!.currentStatusImage())
        lock.setBackgroundImage(statusIMG, for: .normal)
        let powPercent = sesame2!.batteryPrecentage() ?? 0
        power.text = "\(powPercent)%"
        battery.image = UIImage.CHUIImage(named: sesame2!.batteryImage() ?? "bt0")
    }
}

extension DeviceCell: CHSesame2Delegate{

    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if device.deviceId == sesame2?.deviceId,
            status == .receiveBle {
            device.connect(){res in}
        }
        updateUI()
    }
}
