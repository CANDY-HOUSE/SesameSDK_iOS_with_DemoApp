//
//  Sesame5ListCell2.swift
//  SesameUI
//
//  Created by eddy on 2023/12/6.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

@objc(Sesame5ListCell)
class Sesame5ListCell: UITableViewCell {

    @IBOutlet weak var expandableImg: UIImageView!
    @IBOutlet weak var batteryContainer: UIStackView!
    @IBOutlet weak var batteryPercentLab: UILabel!
    
    @IBOutlet weak var batteryTrack: UIImageView!
    @IBOutlet weak var batteryIndicator: UIView!
    @IBOutlet weak var batteryIndicatorWidth: NSLayoutConstraint!
    
    @IBOutlet weak var bleImg: UIImageView!
    @IBOutlet weak var wifiStatusImg: UIImageView!
    
    @IBOutlet weak var deviceNameLab: UILabel!
    @IBOutlet weak var deviceBleStatusLab: UILabel!
    
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak var sesame2CircleBtn: UIButton!
        
    @IBOutlet weak var expandBtn: UIButton!
    @IBOutlet weak var deviceNameMagrinRight: NSLayoutConstraint!
    lazy var sesameUses: [UIView] = {
        [
            batteryContainer,
            batteryPercentLab,
            batteryIndicator,
            bleImg,
            wifiStatusImg,
            deviceNameLab,
            deviceBleStatusLab,
            sesame2Circle,
            sesame2CircleBtn
        ]
    }()
    
    lazy var wifiModuleUnuses: [UIView] = {
        [
            batteryContainer,
            bleImg,
            deviceBleStatusLab,
            sesame2Circle,
            sesame2CircleBtn
        ]
    }()
    var optCallback: ((CHDevice) -> Void)?

    var device: CHDevice!  {
        didSet {
            device.multicastDelegate.addDelegate(self)
            configureSesame2Cell()
            if !(device is CHSesameConnector) {//不是連接器不用
                device.connect() { _ in }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sesame2CircleBtn.titleLabel?.numberOfLines = 3
        prepareHapticFeedback()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onExpandBtnTaped(_ sender: Any) {
        if device.preference.isExpandable {
            optCallback?(device)
        }
    }
    
    @IBAction func onSesame2CircleBtnTapped(_ sender: Any) {
        triggerHapticFeedback()
        (device as? CHSesame5)?.toggle(historytag: device.hisTag) { _ in }
        (device as? CHSesame2)?.toggle { _ in }
        (device as? CHSesameBot)?.click { _ in }
        (device as? CHSesameBike)?.unlock { _ in }
        (device as? CHSesameBike2)?.unlock { _ in }
        if let bot2 = device as? CHSesameBot2 {
            let intValue: Int = UserDefaults.standard.integer(forKey:device.deviceId.uuidString)
            bot2.click(index: UInt8(intValue), result: { _ in })
        }
        (self.device as? CHSesame5)?.setAutoUnlockFlag(false)
        (self.device as? CHSesame2)?.setAutoUnlockFlag(false)
        UserLocationManager.shared.postCHDeviceLocation(device)
    }
    
    func configureSesame2Cell() { // setupSSMCell!!
        if let device = self.device as? CHWifiModule2 {
            configureWifiModuleDevice(device)
        } else {
            configureSesameLockDevice(device!)
        }
        handleExpandIcon(device as CHDevice)
    }
    
    private func handleExpandIcon(_ deviced: CHDevice) {
        expandableImg.isHidden = !deviced.preference.isExpandable
        expandBtn.isHidden = expandableImg.isHidden
        if !deviced.preference.expanded {
            expandableImg.transform = .identity
        }
    }
    
    func configureSesameLockDevice(_ device: CHDevice) {
        UIView.restoreHide(views: sesameUses)
        sesame2Circle.isHidden = (device is CHSesameConnector && device.productModel != .openSensor)//代連裝置右方不用顯示圖標
        deviceNameMagrinRight.priority = sesame2Circle.isHidden ? .defaultLow : .required
        deviceNameLab.text = device.deviceName //名稱
        deviceBleStatusLab.text = device.bluetoothStatusStr()//藍芽狀態文字
        sesame2CircleBtn.setBackgroundImage(UIImage(named: device.currentStatusImage()), for: .normal)//設備撞圖片
        let opensensorState = (device as? CHSesameTouchPro)?.displayedState
        sesame2CircleBtn.setAttributedTitle(opensensorState, for: .normal)
        bleImg.image = UIImage(named: device.bluetoothImageStr())//藍芽小標圖片
        wifiStatusImg.image = UIImage(named: device.wifiImageStr())//wifi小標圖片
        if let mechStatus = device.mechStatus {
            batteryPercentLab.text = "\(mechStatus.getBatteryPrecentage()) %"
            batteryIndicator.backgroundColor =  mechStatus.getBatteryPrecentage() < 15 ?  UIColor.lockRed:  UIColor.sesame2Green
            batteryIndicatorWidth.constant = device.batteryIndicatorWidth() //電量色塊顯示
            if device.productModel == .sesame5 || device.productModel == .sesame5Pro || device.productModel == .sesame5US || device.productModel == .sesame6Pro {
                self.sesame2Circle.refreshUI(newPointerAngle: CGFloat(reverseDegree(angle: mechStatus.position)),lockColor: device.lockColor())
            } else if device.productModel == .sesame2 || device.productModel == .sesame4 {
                self.sesame2Circle.refreshUI(newPointerAngle: CGFloat(angle2degree(angle: mechStatus.position)),lockColor: device.lockColor())
            } else {
                mechStatus.isStop == true ? self.sesame2Circle.stopShake() : self.sesame2Circle.startShake()
                self.sesame2Circle.removeDot()
            }
        } else {
            self.sesame2Circle.stopShake()
            batteryPercentLab.text = ""
            batteryIndicatorWidth.constant = device.batteryIndicatorWidth() //電量色塊顯示
            self.sesame2Circle.removeDot()
        }
        bleImg.isHidden = (device is CHSesameTouchPro) || (device is CHSesameTouch) || (device is CHSesameFace) || (device is CHSesameFacePro)
        batteryContainer.isHidden = ((device is CHSesameTouchPro || (device is CHSesameTouch) || (device is CHSesameFace) || (device is CHSesameFacePro)) && opensensorState == nil)
    }
    
    func configureWifiModuleDevice(_ device: CHWifiModule2) {
        UIView.restoreHide(views: sesameUses)
        UIView.hide(views: wifiModuleUnuses)
        deviceNameLab.text = device.deviceName
        wifiStatusImg.image = UIImage(named: device.wifiImageStr())
    }
    
    func triggerExpand(_ yesOrNo: Bool) {
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.expandableImg.transform = yesOrNo ? CGAffineTransformMakeRotation(.pi * 0.5) : CGAffineTransformIdentity
        }
    }
}

extension Sesame5ListCell: CHDeviceStatusAndKeysDelegate {
    
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String : String]) { }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        if status == .receivedBle() {
            if !(device is CHSesameConnector) {
                device.connect() { _ in }
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

extension Sesame5ListCell: CellConfiguration {
    func configure<T>(item: T) {
        self.device = (item as? CHDevice)
    }
}
