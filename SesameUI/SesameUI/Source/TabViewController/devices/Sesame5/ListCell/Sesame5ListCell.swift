//
//  Sesame5ListCell.swift
//  SesameUI
//
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class Sesame5ListCell: UITableViewCell {
    @IBOutlet weak var battaryZone: UIView!
    @IBOutlet weak var blueZone: UIView!
    @IBOutlet weak var bluetoothStatus: UIImageView!
    @IBOutlet weak var wifiStatus: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel!
    @IBOutlet weak var sesame2AngleLabel: UILabel!
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak var sesame2CircleButton: UIButton!
    @IBOutlet weak var batteryPercentageLabel: UILabel!
    @IBOutlet weak var batteryIndicator: UIView!
    @IBOutlet weak var batteryIndicatorWidth: NSLayoutConstraint!

    var device: CHDevice!  {
        didSet {
            device.delegate = self
            configureSesame2Cell()
            if !(device is CHSesameConnector) {//不是連接器不用
                device.connect() { _ in }
            }
        }
    }

    @IBAction func sesame2CircleTapped(_ sender: Any) {
        (device as? CHSesame5)?.toggle { _ in }
        (device as? CHSesame2)?.toggle { _ in }
        (device as? CHSesameBot)?.click { _ in }
        (device as? CHSesameBike)?.unlock { _ in }
        (device as? CHSesameBike2)?.unlock { _ in }
        (self.device as? CHSesame5)?.setAutoUnlockFlag(false)
        (self.device as? CHSesame2)?.setAutoUnlockFlag(false)
        UserLocationManager.shared.postCHDeviceLocation(device)
//        self.sesame2Circle.startShake()
    }
    
    func configureSesame2Cell() { // setupSSMCell!!
        sesame2Circle.isHidden = (device is CHSesameConnector)//代連裝置右方不用顯示圖標

        deviceNameLabel.text = device.deviceName //名稱
        sesame2StatusLabel.text = device.bluetoothStatusStr()//藍芽狀態文字
        sesame2CircleButton.setBackgroundImage(UIImage(named: device.currentStatusImage()), for: .normal)//設備撞圖片
        bluetoothStatus.image = UIImage(named: device.bluetoothImageStr())//藍芽小標圖片
        wifiStatus.image = UIImage(named: device.wifiImageStr())//wifi小標圖片
        
        if let mechStatus = device.mechStatus {
            batteryPercentageLabel.text = "\(mechStatus.getBatteryPrecentage()) %"
            batteryIndicator.backgroundColor =  mechStatus.getBatteryPrecentage() < 15 ?  UIColor.lockRed:  UIColor.sesame2Green 
            batteryIndicatorWidth.constant = device.batteryIndicatorWidth() //電量色塊顯示
            
            if (device.productModel == .sesame5 || device.productModel == .sesame5Pro) {
                self.sesame2Circle.refreshUI(newPointerAngle:CGFloat(reverseDegree(angle: mechStatus.position)),lockColor: device.lockColor())
            } else if ((device.productModel == .sesame2) || (device.productModel == .sesame4) ) {
                self.sesame2Circle.refreshUI(newPointerAngle: CGFloat(angle2degree(angle: mechStatus.position)),lockColor: device.lockColor())
            }else{
                self.sesame2Circle.removeDot()
                if(device.mechStatus!.isStop == true){
                    self.sesame2Circle.stopShake()
                }else{
                    self.sesame2Circle.startShake()
                }
            }
        }
        blueZone.isHidden = (device is CHSesameTouchPro)
        battaryZone.isHidden = (device is CHSesameTouchPro)
    }
}

extension Sesame5ListCell: CHDeviceStatusDelegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        if status == .receivedBle() {
            if !(device is CHSesameConnector) {
                device.connect() { _ in }

            }else{
//                device.connect() { _ in }
            }
        }
        executeOnMainThread {
            self.configureSesame2Cell()
        }
    }

    func onMechStatus(device: CHDevice) {
        executeOnMainThread {
            self.configureSesame2Cell()
        }
    }
}

