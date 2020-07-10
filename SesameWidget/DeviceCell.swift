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
        ssm?.toggleWithHaptic(interval: 1.5)
    }
    @IBOutlet weak var circle: SesameCircle!
    public var ssm: CHSesame2?{
        didSet{
            ssm?.delegate = self
            updateUI()

            ownerName.isHidden = true
            ownerName.text = ""
            
            let device = SSMStore.shared.getPropertyForDevice(ssm!)
            deviceName.text = device.name ?? device.deviceID!.uuidString
            
            if #available(iOSApplicationExtension 13.0, *) {
                ownerName.textColor = UIColor.placeholderText
                power.textColor = UIColor.placeholderText
            }
        }
    }
    
    func updateUI()  {
        var currentDegree: Float = 0.0
        if let status = ssm?.mechStatus,
            let currentAngle = status.getPosition() {
            currentDegree = angle2degree(angle: Int16(currentAngle))
        }

        circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                         lockColor: ssm!.lockColor())
        let statusIMG = UIImage.CHUIImage(named: ssm!.currentStatusImage())
        lock.setBackgroundImage(statusIMG, for: .normal)
        let powPercent = ssm!.batteryPrecentage() ?? 0
        power.text = "\(powPercent)%"
        battery.image = UIImage.CHUIImage(named: ssm!.batteryImage() ?? "bt0")
    }
}

extension DeviceCell:CHSesameDelegate{

    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHDeviceStatus) {
        if device.deviceId == ssm?.deviceId,
            status == .receiveBle {
            device.connect()
        }
        updateUI()
    }
}
