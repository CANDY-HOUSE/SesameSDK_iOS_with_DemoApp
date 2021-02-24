//
//  Sesame2ListCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

protocol Sesame2ListCellDelegate: class {
    func sesame2CircleTapped(_ cell: Sesame2ListCell)
    func debugModeTapped(_ cell: Sesame2ListCell)
}

extension Sesame2ListCellDelegate {
    func sesame2CircleTapped(_ cell: Sesame2ListCell) {}
    func debugModeTapped(_ cell: Sesame2ListCell) {}
}

class Sesame2ListCell: UITableViewCell {

    @IBOutlet weak var bluetoothStatus: UIImageView! {
        didSet {
            bluetoothStatus.image = UIImage.CHUIImage(named: "bluetooth_gray")
        }
    }
    @IBOutlet weak var wifiStatus: UIImageView! {
        didSet {
            wifiStatus.image = UIImage.CHUIImage(named: "wifi_gray")
        }
    }
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel! {
        didSet {
            sesame2StatusLabel.adjustsFontSizeToFitWidth = true
            sesame2StatusLabel.minimumScaleFactor = 0.1
            sesame2StatusLabel.numberOfLines = 1
        }
    }
    @IBOutlet weak var sesame2ShadowStatusLabel: UILabel! {
        didSet {
            sesame2ShadowStatusLabel.adjustsFontSizeToFitWidth = true
            sesame2ShadowStatusLabel.minimumScaleFactor = 0.1
            sesame2ShadowStatusLabel.numberOfLines = 1
        }
    }
    @IBOutlet weak var sesame2AngleLabel: UILabel!
    
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak var sesame2CircleButton: UIButton!
    @IBOutlet weak var batteryPercentageLabel: UILabel!
    @IBOutlet weak var batteryImageView: UIImageView!
    @IBOutlet weak var debugModeButton: UIButton! {
        didSet {
            debugModeButton.isHidden = true
        }
    }
    @IBOutlet weak var keyLevelLabel: UILabel!
    
    weak var delegate: Sesame2ListCellDelegate?
    var sesame2: CHSesame2? {
        didSet {
            sesame2?.delegate = self
            sesame2?.connect() { _ in
                
            }
            configureSesame2Cell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        changeTextColor()
    }
    
    func changeTextColor() {
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                keyLevelLabel.textColor = .placeHolderColor
                batteryPercentageLabel.textColor = .placeHolderColor
                sesame2StatusLabel.textColor = .placeHolderColor
                sesame2AngleLabel.textColor = .placeHolderColor
            } else {
                keyLevelLabel.textColor = .lightGray
                batteryPercentageLabel.textColor = .lightGray
                sesame2StatusLabel.textColor = .lightGray
                sesame2AngleLabel.textColor = .lightGray
            }
        } else {
            keyLevelLabel.textColor = .placeHolderColor
            batteryPercentageLabel.textColor = .placeHolderColor
            sesame2StatusLabel.textColor = .placeHolderColor
            sesame2AngleLabel.textColor = .placeHolderColor
        }
    }
    
    let toggleDebouncer = Debouncer()

    @IBAction func sesame2CircleTapped(_ sender: Any) {
        toggleDebouncer.execute {
            self.sesame2?.toggle { _ in }
            self.delegate?.sesame2CircleTapped(self)
        }
    }
    
    @IBAction func debugModeTapped(_ sender: Any) {
        delegate?.debugModeTapped(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        changeTextColor()
    }
}

extension Sesame2ListCell: CHSesame2Delegate {
    func onBleDeviceStatusChanged(device: SesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle() {
            device.connect() { _ in

            }
        }
        executeOnMainThread {
            self.sesame2Circle.refreshUI(lockColor: (device as! CHSesame2).lockColor())
            self.configureSesame2Cell()
        }
    }
    
    func onMechStatusChanged(device: CHSesame2, status: SesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            let batteryPercentage = "\(status.getBatteryPrecentage()) %"
            let lockAngle = CGFloat(angle2degree(angle: status.position))
            self.batteryPercentageLabel.text = batteryPercentage
            self.sesame2Circle.refreshUI(newPointerAngle: lockAngle,
                                         lockColor: device.lockColor())
            self.sesame2AngleLabel.text = ""
        }
    }
    
    // MARK: - configureSesame2Cell
    func configureSesame2Cell() {
        guard let sesame2 = self.sesame2 else {
            return
        }
        deviceNameLabel.text = sesame2.deviceName
        
        sesame2ShadowStatusLabel.text = ""
        sesame2StatusLabel.text = isHideBleStatus() ? "" : sesame2.deviceStatus.description
        
        debugModeButton.isHidden = true
        sesame2CircleButton.setBackgroundImage(UIImage.CHUIImage(named: sesame2.currentStatusImage()), for: .normal)

        updateBluetoothStatus()
        updateWifiStatus()
        
        batteryImageView.image = UIImage.CHUIImage(named: sesame2.batteryImage())
        if let mechStatu = sesame2.mechStatus {
            let lockAngle = CGFloat(angle2degree(angle: mechStatu.position))
            self.sesame2Circle.refreshUI(newPointerAngle: lockAngle,
                                         lockColor: sesame2.lockColor())
        }
        keyLevelLabel.text = ""
    }
    
    func isHideBleStatus() -> Bool {
        return sesame2?.deviceStatus.loginStatus == .logined || sesame2?.deviceStatus == .noBleSignal()
    }
    
    func updateBluetoothStatus() {
        var bluetoothStatusImage: UIImage!
        if sesame2?.bluetoothColor() == .lockGray {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_gray")
        } else if sesame2?.bluetoothColor() == .lockYellow {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_yellow")
        } else if sesame2?.bluetoothColor() == .sesame2Green {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_green")
        } else if sesame2?.bluetoothColor() == .lockRed {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_red")
        }
//        debugModeButton.isHidden = true
        bluetoothStatus.image = bluetoothStatusImage
    }
    
    func updateWifiStatus() {
        var wifiStatusImage: UIImage!
        if sesame2?.wifiColor() == .lockGray {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_gray")
        } else if sesame2?.wifiColor() == .lockYellow {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_yellow")
        } else if sesame2?.wifiColor() == .sesame2Green {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_green")
        } else if sesame2?.wifiColor() == .lockRed {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_red")
        }
//        debugModeButton.isHidden = true
        wifiStatus.image = wifiStatusImage
    }
}
