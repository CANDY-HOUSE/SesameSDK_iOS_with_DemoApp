//
//  WifiModule2ListCell.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

protocol WifiModule2ListCellDelegate: class {
    func circleButtonDidTapped(_ cell: WifiModule2ListCell)
}

extension WifiModule2ListCellDelegate {
    func circleButtonDidTapped(_ cell: WifiModule2ListCell) {}
}

class WifiModule2ListCell: UITableViewCell {
    
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var bluetoothStatus: UIImageView!
    @IBOutlet weak var wifiStatus: UIImageView!
    
    @IBOutlet weak var deviceNameLabel: UILabel! {
        didSet {
            deviceNameLabel.adjustsFontSizeToFitWidth = true
            deviceNameLabel.minimumScaleFactor = 0.1
            deviceNameLabel.numberOfLines = 1
        }
    }
    @IBOutlet weak var sesame2CircleButton: UIButton! {
        didSet {
            sesame2CircleButton.addTarget(self, action: #selector(buttonDidTapped), for: .touchUpInside)
//            sesame2CircleButton.isHidden = true
        }
    }
    @IBOutlet weak var sesame2StatusLabel: UILabel!
    @IBOutlet weak var sesame2ShadowStatusLabel: UILabel! {
        didSet {
            sesame2ShadowStatusLabel.textColor = .sesame2Green
        }
    }
    @IBOutlet weak var sesame2AngleLabel: UILabel! {
        didSet {
            sesame2AngleLabel.isHidden = true
        }
    }
    weak var delegate: WifiModule2ListCellDelegate?
    var wifiModule2: CHWifiModule2? {
        didSet {
            wifiModule2?.delegate = self
            configureWifiModule2Cell()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func buttonDidTapped() {
        delegate?.circleButtonDidTapped(self)
    }
    
}

// MARK: - CHWifiModule2Delegate
extension WifiModule2ListCell: CHWifiModule2Delegate {
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHSesame2Status) {
        executeOnMainThread {
            self.configureWifiModule2Cell()
        }
    }
    
    func onNetworkStatusChanged(device: CHWifiModule2, status: CHWifiModule2NetworkStatus) {
        executeOnMainThread {
            self.configureWifiModule2Cell()
        }
    }
    
    // MARK: - configureWifiModule2Cell
    func configureWifiModule2Cell() {
        guard let wifiModule2 = wifiModule2 else {
            return
        }
        deviceNameLabel.text = wifiModule2.deviceName
        
        sesame2ShadowStatusLabel.text = ""
        sesame2StatusLabel.text = isHideBleStatus() ? "" : wifiModule2.deviceStatus.description
        
        wifiStatus.image = UIImage.SVGImage(named: "wifi", fillColor: wifiModule2.wifiColor())
        bluetoothStatus.image = UIImage.SVGImage(named: "bluetooth", fillColor: wifiModule2.bluetoothColor())
    }
    
    func isHideBleStatus() -> Bool {
//        return wifiModule2!.deviceStatus.loginStatus == .logined || wifiModule2!.deviceStatus == .noBleSignal()
        true
    }
}
