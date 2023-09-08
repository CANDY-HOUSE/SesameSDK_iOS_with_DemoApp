//
//  WifiModule2ListCell.swift
//  SesameUI
//
//  Created by tse on 2023/05/06.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class WifiModule2ListCell: UITableViewCell {
    @IBOutlet weak var wifiStatus: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    var wifiModule2: CHWifiModule2! {
        didSet {
            wifiModule2.delegate = self
            configureWifiModule2Cell()
        }
    }
}

extension WifiModule2ListCell: CHWifiModule2Delegate {
    func onSesame2KeysChanged(device: SesameSDK.CHWifiModule2, sesame2keys: [String : String]) {

    }

    func onBleDeviceStatusChanged(device: SesameSDK.CHDevice, status: SesameSDK.CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        executeOnMainThread {
            self.configureWifiModule2Cell()
        }
    }

    func onMechStatus(device: CHDevice) {
        executeOnMainThread {
            self.configureWifiModule2Cell()
        }
    }
    
    func configureWifiModule2Cell() {
        deviceNameLabel.text = wifiModule2.deviceName
        wifiStatus.image = UIImage(named: wifiModule2.wifiImageStr())
    }

}
