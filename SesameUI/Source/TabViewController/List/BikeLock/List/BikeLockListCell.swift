//
//  BikeLockListCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

protocol BikeLockListCellDelegate: class {
    func bikeLockCircleTapped(_ cell: BikeLockListCell)
    func debugModeTapped(_ cell: BikeLockListCell)
}

extension BikeLockListCellDelegate {
    func bikeLockCircleTapped(_ cell: BikeLockListCell) {}
    func debugModeTapped(_ cell: BikeLockListCell) {}
}

class BikeLockListCell: UITableViewCell {

    @IBOutlet weak var bluetoothStatus: UIImageView!
    @IBOutlet weak var wifiStatus: UIImageView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel!
    @IBOutlet weak var sesame2ShadowStatusLabel: UILabel!
    
    @IBOutlet weak var sesame2Circle: ShakeCircle!
    @IBOutlet weak var sesame2CircleButton: UIButton!
    @IBOutlet weak var batteryPercentageLabel: UILabel!
    @IBOutlet weak var batteryImageView: UIImageView!
    @IBOutlet weak var debugModeButton: UIButton! {
        didSet {
            debugModeButton.isHidden = true
        }
    }
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var keyLevelLabel: UILabel!
    
    var indexPath: IndexPath!
    var bikeLock: CHSesameBike? {
        didSet {
            bikeLock?.delegate = self
            bikeLock?.connect() { _ in
                
            }
            self.configureBikeLockCell()
        }
    }
    
    weak var delegate: BikeLockListCellDelegate?
    
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
            } else {
                keyLevelLabel.textColor = .lightGray
                batteryPercentageLabel.textColor = .lightGray
                sesame2StatusLabel.textColor = .lightGray
            }
        } else {
            keyLevelLabel.textColor = .placeHolderColor
            batteryPercentageLabel.textColor = .placeHolderColor
            sesame2StatusLabel.textColor = .placeHolderColor
        }
    }
    
    @IBAction func sesame2CircleTapped(_ sender: Any) {
        bikeLock?.unlock { _ in }
        delegate?.bikeLockCircleTapped(self)
    }
    
    @IBAction func debugModeTapped(_ sender: Any) {
        delegate?.debugModeTapped(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        changeTextColor()
    }
    
    var intention = "idle"
}

// MARK: - CHSesameBikeDelegate
extension BikeLockListCell: CHSesameBikeDelegate {
    func onBleDeviceStatusChanged(device: CHSesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle() {
            device.connect() {_ in}
        }
        executeOnMainThread {
            self.configureBikeLockCell()
        }
    }
    
    func onMechStatusChanged(device: CHSesameBike, status: CHSesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            
            var intentionString = ""
            switch intention {
            case .idle:
                intentionString = "idle"
            case .locking:
                intentionString = "locking"
            case .unlocking:
                intentionString = "unlocking"
            case .movingToUnknownTarget:
                intentionString = "movingToUnknownTarget"
            @unknown default:
                break
            }
            
            if intentionString != self.intention {
                self.intention = intentionString
                switch intention {
                case .unlocking:
                    self.sesame2Circle.startShake()
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - configureBikeLockCell
    func configureBikeLockCell() {
        guard let bikeLock = bikeLock else {
            return
        }
        deviceNameLabel.text = bikeLock.deviceName
        sesame2ShadowStatusLabel.text = ""
        sesame2StatusLabel.text = isHideBleStatus() ? "" : bikeLock.deviceStatus.description
        
        debugModeButton.isHidden = true
        
        if bikeLock.currentStatusImage() == "bike_1" {
            statusImage.image = UIImage.CHUIImage(named: bikeLock.currentStatusImage())!
            sesame2CircleButton.setBackgroundImage(nil, for: .normal)
        } else {
            statusImage.image = nil
            sesame2CircleButton.setBackgroundImage(UIImage.CHUIImage(named: bikeLock.currentStatusImage()), for: .normal)
        }
        
        if let mechStatus = bikeLock.mechStatus {
            let batteryPercentage = "\(mechStatus.getBatteryPrecentage()) %"
            batteryPercentageLabel.text = batteryPercentage
        }
        
        var wifiStatusImage: UIImage!
        var bluetoothStatusImage: UIImage!
        if bikeLock.wifiColor() == .lockGray {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_gray")
        } else if bikeLock.wifiColor() == .lockYellow {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_yellow")
        } else if bikeLock.wifiColor() == .sesame2Green {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_green")
        } else if bikeLock.wifiColor() == .lockRed {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_red")
        }
        
        if bikeLock.bluetoothColor() == .lockGray {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_gray")
        } else if bikeLock.bluetoothColor() == .lockYellow {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_yellow")
        } else if bikeLock.bluetoothColor() == .sesame2Green {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_green")
        } else if bikeLock.bluetoothColor() == .lockRed {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_red")
        }
        wifiStatus.image = wifiStatusImage
        bluetoothStatus.image = bluetoothStatusImage
        batteryImageView.image = UIImage.CHUIImage(named: bikeLock.batteryImage())
        keyLevelLabel.text = ""
    }
    
    func isHideBleStatus() -> Bool {
        return bikeLock!.deviceStatus.loginStatus == .logined || bikeLock!.deviceStatus == .noBleSignal()
    }
}
