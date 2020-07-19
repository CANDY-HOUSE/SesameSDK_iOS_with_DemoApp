//
//  BluetoothSesameControlViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/8/6.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import CoreBluetooth

class BluetoothSesame2ControlViewController: CHBaseViewController, CHSesame2Delegate {    
    var sesame: CHSesame2?

    var timer: Timer?
    
    @IBOutlet weak var shareKeyImg: UIImageView!
    @IBOutlet weak var lockIntention: UILabel!
    @IBOutlet weak var Interval: UITextField!
    @IBOutlet weak var timesInput: UITextField!
    @IBOutlet weak var versionTagBtn: UIButton!
    @IBOutlet weak var lockCircle: Knob!
    @IBOutlet weak var gattStatusLB: UILabel!
    @IBOutlet weak var unlockSetBtn: UIButton!
    @IBOutlet weak var lockSetBtn: UIButton!
    @IBOutlet weak var resultLB: UILabel!
    @IBOutlet weak var angleLB: UILabel!
    @IBOutlet weak var lockstatusLB: UILabel!
    @IBOutlet weak var nicknameLB: UILabel!
    @IBOutlet weak var deviceIDLB: UILabel!
    @IBOutlet weak var bleIDLB: UILabel!
    @IBOutlet weak var enableAutolockBtn: UIButton!
    @IBOutlet weak var disableAutolockBtn: UIButton!
    @IBOutlet weak var registStatusLB: UILabel!
    @IBOutlet weak var powerLB: UILabel!
    @IBOutlet weak var fwVersionLB: UILabel!
    @IBOutlet weak var autolockLB: UILabel!
    @IBOutlet weak var userTable: UITableView!
    var dfuHelper: CHDFUHelper?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    @IBAction func lockdegree(_ sender: Any) {
        lockDegree = nowDegree
    }
    @IBAction func generateKey(_ sender: UIButton) {
        
        // no use
        let title = sender.titleLabel?.text!
        if(title!.contains("manager")){
            issueAnQRCodeKey(imgv: self.shareKeyImg,level: .manager)
        }
        if(title!.contains("guest")){
            issueAnQRCodeKey(imgv: self.shareKeyImg,level: .guest)
        }
        shareKeyImg.image = UIImage.CHUIImage(named: "loading")
    }
    
    @IBAction func refreshUserList(_ sender: Any) {
        //        self.sesame?.getDeviceMembers() { result in
        //            switch result {
        //            case .success(let users):
        //                DispatchQueue.main.async {
        //                    self.userList = users.data
        //                    self.userTable.reloadData()
        //                }
        //            case .failure(let error):
        //                L.d(ErrorMessage.descriptionFromError(error: error))
        //                DispatchQueue.main.async {
        //                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
        //                }
        //            }
        //        }
    }
    
    @objc func timerUpdate() {
        guard let _ = self.mechStatus else {
            return
        }
        let times = Int(timesInput.text!)
        if(times! == 1) {
            self.timer?.invalidate()
        }
        
//        sesame?.getAutolockSetting { [weak self] autoLockTime in
//            guard let strongSelf = self else {
//                return
//            }
//            if autoLockTime == 0 {
//                strongSelf.sesame?.toggleWithHaptic(interval: 1.5)
//            } else {
//                strongSelf.sesame?.toggleWithHaptic(interval: TimeInterval(autoLockTime)+3.0)
//            }
//        }
        sesame?.getAutolockSetting { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
//                strongSelf.switchIsOn = delay.data != 0
                if delay.data == 0 {
                    strongSelf.sesame?.toggleWithHaptic(interval: 1.5)
                } else {
                    strongSelf.sesame?.toggleWithHaptic(interval: TimeInterval(delay.data)+3.0)
                }

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func startLock(_ sender: Any) {
        self.timer?.invalidate()
        
        let second =  Int(self.Interval.text!)!
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(second), target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    @IBAction func stopLock(_ sender: Any) {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @IBAction func versionTagClick(_ sender: UIButton) {
        sesame!.getVersionTag { result in
            switch result {
            case .success(let status):
                DispatchQueue.main.async {
                    sender.setTitle(status.data, for: .normal)
                }
            case .failure(_):
                break
            }
        }
    }
    
    @IBAction func unlockdegree(_ sender: Any) {
        unlockDegree = nowDegree
    }
    
    @IBAction func readAutolockClick(_ sender: UIButton) {
        
//        self.sesame!.getAutolockSetting { (delay) -> Void in
//            self.autolockLB.text = String(delay)
//        }
        sesame?.getAutolockSetting { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
                //                strongSelf.switchIsOn = delay.data != 0
                strongSelf.autolockLB.text = String(delay.data)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
    }
    
    @IBAction func dufClick(_ sender: UIButton) {
        do {
            let zipData = try Data(contentsOf: Constant.resourceBundle.url(forResource: nil, withExtension: ".zip")!)
            self.sesame?.updateFirmware({ result in
                switch result {
                case .success(let peripheral):
                    guard let peripheral = peripheral.data else {
                        ViewHelper.alert("Error", "Update Error", self)
                        return
                    }
                    self.dfuHelper = CHDFUHelper(peripheral: peripheral, zipData: zipData)
                    let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
                        
                    }
                    progressIndicator.dfuInitialized {
                        self.dfuHelper?.abort()
                        self.dfuHelper = nil
                    }
                    self.dfuHelper?.observer = progressIndicator
                    self.dfuHelper?.start()
                case .failure(let error):
                    L.d(error.errorDescription())
                    self.view.makeToast(error.errorDescription())
                }
            })
        } catch {
            ViewHelper.alert("Error", "Update Error: \(error)", self)
        }
    }
    
    @IBAction func enableAutolock(_ sender: Any) {
        let alert = UIAlertController(title: "Autolock", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input your delay second here..."
            textField.keyboardType = .numberPad
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let second = alert.textFields?.first?.text {
                self.sesame?.enableAutolock(delay:  Int(second)!){ (delay) -> Void in
                }
                
            }
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func disableAutolock(_ sender: Any) {
        self.sesame!.disableAutolock(){ (result) -> Void in}
    }
    
    @IBAction func unregisterServer(_ sender: Any) {
//        self.sesame?.unregisterServer(){ result in
//            switch result {
//            case .success(_):
//                self.sesame?.unregister()
//            case .failure(let error):
//                ViewHelper.alert("Error", ErrorMessage.descriptionFromError(error: error), self)
//                DispatchQueue.main.async {
//                    ViewHelper.hideLoadingView(view: self.view)
//                }
//            }
//        }
    }
    @IBAction func unregisterClick(_ sender: UIButton) {
        self.sesame!.resetSesame(){res in

        }
    }
    
    @IBAction func setLock(_ sender: UIButton) {
        sesame!.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in

        }
    }
    
    @IBAction func unlockClick(_ sender: UIButton) {
        sesame!.unlock { _ in
            
        }
    }
    
    @IBAction func lockClick(_ sender: UIButton) {
        sesame!.lock { _ in
            
        }
    }
    
    @IBAction func connectClick(_ sender: UIButton) {
        sesame!.connect(){res in}
    }
    
    @IBAction func disConnect(_ sender: Any) {
        sesame!.disconnect(){res in}
    }
    
    @IBAction func registerBtn(_ sender: Any) {
        let alert = UIAlertController(title: "sesame name", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input your sesame name here..."
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let name = alert.textFields?.first?.text {
                // TODO: To be implemenated
                //                self.sesame!.register(nickname: name, {(result) in
                //                    switch result {
                //                    case .success(_):
                //                        CHAccountManager.shared.refreshKeychain({ result in
                //                            switch result {
                //                            case .success(_):
                //                                ViewHelper.showAlertMessage(title: "flushDevices", message: "success", actionTitle: "ok", viewController: self)
                //                            case .failure(let error):
                //                                DispatchQueue.main.async {
                //                                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                //                                }
                //                                L.d(ErrorMessage.descriptionFromError(error: error))
                //                            }
                //                        })
                //                    case .failure(let error):
                //                        DispatchQueue.main.async {
                //                            self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                //                        }
                //                        L.d(ErrorMessage.descriptionFromError(error: error))
                //                    }
                //                })
            }
        }))
        self.present(alert, animated: true)
    }
    
    var mechStatus: CHSesame2MechStatus? {
        didSet {
            guard let status = mechStatus else {
                return
            }
            nowDegree = Int16(status.getPosition()!)
            lockstatusLB.text = status.isInLockRange()! ? "locked" : status.isInUnlockRange()! ? "unlocked" : "moved"
            //            let batteryStatus: CHBatteryStatus = status.getBatteryVoltage()
            //            powerLB.text = "battery:\(batteryStatus.description()),\(status.getBatteryVoltage())"
        }
    }
    
    var mechSetting: CHSesame2MechSettings? {
        didSet {
            guard let setting = mechSetting else {
                return
            }
            lockDegree = Int16(setting.getLockPosition()!)
            unlockDegree = Int16(setting.getUnlockPosition()!)
            lockSetBtn.setTitle("\(setting.getLockPosition()!)", for: .normal)
            unlockSetBtn.setTitle("\(setting.getUnlockPosition()!)", for: .normal)
            lockCircle.setLock(self.sesame!)
//            fwVersionLB.text = "\(self.sesame!.fwVersion)"
        }
    }
    
    var deviceStatus: CHSesame2Status = CHSesame2Status.noSignal {
        didSet {
            DispatchQueue.main.async(execute: {
                self.gattStatusLB.text = "\(self.deviceStatus.description())"
            })
        }
    }
    
    var isRegisted: Bool? {
        didSet {
            DispatchQueue.main.async {
                self.registStatusLB.text = self.isRegisted! ? "registered":"unregistered"
            }
        }
    }
    
    var nowDegree: Int16 = 0 {
        didSet {
            angleLB.text = "angle:\(nowDegree)"
            lockCircle.setValue(angle2degree(angle: nowDegree))
        }
    }
    
    var lockDegree: Int16 = 0 {
        didSet {
            lockSetBtn.setTitle(String(lockDegree), for: .normal)
        }
    }
    
    var unlockDegree: Int16 = 0 {
        didSet {
            unlockSetBtn.setTitle(String(unlockDegree), for: .normal)
        }
    }
    
    
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
//        L.d("test",status.description())
        deviceStatus = status

        if(deviceStatus == .receiveBle){
            device.connect(){_ in}
        }
        
        
        if(deviceStatus.loginStatus() == .login){
            //            DispatchQueue.main.async {
            self.mechSetting = device.mechSetting
            self.mechStatus = device.mechStatus
            //            }
        }
    }
    
    
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        DispatchQueue.main.async {
            self.mechStatus = status
            self.lockIntention.text = intention.description
        }
    }
    
//    func onBleCommandResult(device: CHSesame2, command: Sesame22ItemCode, returnCode: BLECmdResultCode){
//        DispatchQueue.main.async {
//            self.resultLB.text = "\(command.plainName),\(returnCode)"
//            
//            //            L.d("\(command.description()),\(returnCode.description())")
//            if command == .lock || command == .unlock && returnCode == .success {
//                let times = Int(self.timesInput.text!)
//                if times! > 0 {
//                    self.timesInput.text = "\(times! - 1)"
//                }
//            }
//        }
//    }
}

extension BluetoothSesame2ControlViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    func deleteUser(_ user:  UUID?) {
        
    }
}

extension BluetoothSesame2ControlViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sesame?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isRegisted = sesame!.isRegistered
        mechStatus = sesame!.mechStatus
        mechSetting = sesame!.mechSetting
        deviceStatus = sesame!.deviceStatus
        
        //        deviceIDLB.text = "accessLevel:\(sesame!.accessLevel.rawValue)"
        //        bleIDLB.text = "BleId:\(sesame!.bleIdStr)"
        //        nicknameLB.text="customNickname:\(sesame!.customDeviceName)"
        shareKeyImg.image = UIImage.CHUIImage(named: "refresh")
        
        //        if(self.sesame!.accessLevel == .manager  || self.sesame!.accessLevel == .owner   ){
        self.refreshUserList(self)
        //        }
        sesame!.connect(){_ in}
    }
    
    func issueAnQRCodeKey(imgv:UIImageView , level:CHDeviceAccessLevel) {

    }
}
