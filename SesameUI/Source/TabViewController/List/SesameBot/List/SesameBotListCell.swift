//
//  SesameBotListCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

protocol SesameBotListCellDelegate: class {
    func sesameBotCircleTapped(_ cell: SesameBotListCell)
    func debugModeTapped(_ cell: SesameBotListCell)
}

extension SesameBotListCellDelegate {
    func sesameBotCircleTapped(_ cell: SesameBotListCell) {}
    func debugModeTapped(_ cell: SesameBotListCell) {}
}

class SesameBotListCell: UITableViewCell {

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
    
    weak var delegate: SesameBotListCellDelegate?
    var sesameBot: CHSesameBot? {
        didSet {
            sesameBot?.delegate = self
            sesameBot?.connect() { _ in

            }
            configureCell()
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
        delegate?.sesameBotCircleTapped(self)
        
        sesameBot?.click(result: { _ in
            
        })
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

// MARK: - CHSwitchDelegate
extension SesameBotListCell: CHSesameBotDelegate {
    func onBleDeviceStatusChanged(device: SesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle() {
            device.connect() {_ in}
        }
        executeOnMainThread {
            self.configureCell()
        }
    }
    
    func onMechStatusChanged(device: CHSesameBot, status: SesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            
            var intentionString = ""
            switch intention {
            case .idle:
                intentionString = "idle"
            case .movingToUnknownTarget:
                intentionString = "movingToUnknownTarget"
            case .locking:
                break
            case .unlocking:
                break
            @unknown default:
                break
            }
            
            if intentionString != self.intention {
                self.intention = intentionString
                switch intention {
                case .movingToUnknownTarget:
                    self.sesame2Circle.startShake()
                case .idle:
                    self.sesame2Circle.stopShake()
                default:
                    break
                }
            }
            self.configureCell()
        }
    }
    
    // MARK: - configureCell
    func configureCell() {
        
        guard let sesameBot = sesameBot else {
            return
        }
        deviceNameLabel.text = sesameBot.deviceName

        sesame2ShadowStatusLabel.text = ""
        sesame2StatusLabel.text = isHideBleStatus() ? "" : sesameBot.deviceStatus.description
        
        sesame2CircleButton.setBackgroundImage(UIImage.CHUIImage(named: sesameBot.currentStatusImage()), for: .normal)
        
        if let mechStatus = sesameBot.mechStatus {
            let batteryPercentage = "\(mechStatus.getBatteryPrecentage()) %"
            batteryPercentageLabel.text = batteryPercentage
        }
        
        var wifiStatusImage: UIImage!
        var bluetoothStatusImage: UIImage!
        
        if sesameBot.wifiColor() == .lockGray {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_gray")
        } else if sesameBot.wifiColor() == .lockYellow {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_yellow")
        } else if sesameBot.wifiColor() == .sesame2Green {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_green")
        } else if sesameBot.wifiColor() == .lockRed {
            wifiStatusImage = UIImage.CHUIImage(named: "wifi_red")
        }
        
        if sesameBot.bluetoothColor() == .lockGray {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_gray")
        } else if sesameBot.bluetoothColor() == .lockYellow {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_yellow")
        } else if sesameBot.bluetoothColor() == .sesame2Green {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_green")
        } else if sesameBot.bluetoothColor() == .lockRed {
            bluetoothStatusImage = UIImage.CHUIImage(named: "bluetooth_red")
        }
        wifiStatus.image = wifiStatusImage
        bluetoothStatus.image = bluetoothStatusImage
        batteryImageView.image = UIImage.CHUIImage(named: sesameBot.batteryImage())
        keyLevelLabel.text = ""
        debugModeButton.isHidden = true
    }
    
    func isHideBleStatus() -> Bool {
        return sesameBot!.deviceStatus.loginStatus == .logined || sesameBot!.deviceStatus == .noBleSignal()
    }
}
