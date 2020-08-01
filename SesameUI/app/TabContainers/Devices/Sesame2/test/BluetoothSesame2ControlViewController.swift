//
//  BluetoothSesameControlViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/8/6.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import CoreBluetooth

class BluetoothSesame2ControlViewController: CHBaseViewController, CHSesame2Delegate {    
    var sesame: CHSesame2?

    var timer: Timer?
    @IBOutlet weak var deviceIDLB: UILabel!
    @IBOutlet weak var lockIntention: UILabel!
    @IBOutlet weak var Interval: UITextField!
    @IBOutlet weak var timesInput: UITextField!
    @IBOutlet weak var versionTagBtn: UIButton!
    @IBOutlet weak var gattStatusLB: UILabel!
    @IBOutlet weak var unlockSetBtn: UIButton!
    @IBOutlet weak var lockSetBtn: UIButton!
    @IBOutlet weak var angleLB: UILabel!
    @IBOutlet weak var lockstatusLB: UILabel!

    @IBOutlet weak var enableAutolockBtn: UIButton!
    @IBOutlet weak var disableAutolockBtn: UIButton!
    @IBOutlet weak var registStatusLB: UILabel!
    @IBOutlet weak var powerLB: UILabel!
    @IBOutlet weak var autolockLB: UILabel!
    var dfuHelper: CHDFUHelper?
    

    @IBAction func lockdegree(_ sender: Any) {
        lockDegree = nowDegree
    }

    @objc func timerUpdate() {
        guard let _ = self.mechStatus else {
            return
        }
        let times = Int(timesInput.text!)
        if(times! == 1) {
            self.timer?.invalidate()
        }

        sesame?.toggle(){_ in}
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
        let alert = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.AutoLock".localized,
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                      style: .cancel,
                                      handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input your delay second here..."
            textField.keyboardType = .numberPad
        })
        alert.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.OK".localized,
                                      style: .default,
                                      handler: { _ in
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

    @IBAction func unregisterClick(_ sender: UIButton) {
        self.sesame!.resetSesame2(){res in}
    }
    
    @IBAction func setLock(_ sender: UIButton) {
        sesame!.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ _ in}
    }
    
    @IBAction func unlockClick(_ sender: UIButton) {
        sesame!.unlock { _ in }
    }
    
    @IBAction func lockClick(_ sender: UIButton) {
        sesame!.lock { _ in} // default with set historytag , check with  gethistorytag
//      sesame!.lock(historytag:Data(hex: "11223344")){_ in}
    }
    
    @IBAction func connectClick(_ sender: UIButton) {
        sesame!.connect(){res in}
    }
    
    @IBAction func disConnect(_ sender: Any) {
        sesame!.disconnect(){res in}
    }
    
    @IBAction func registerBtn(_ sender: Any) {
        sesame!.registerSesame2(){ _ in}
    }
    
    var mechStatus: CHSesame2MechStatus? {
        didSet {
            guard let status = mechStatus else {
                return
            }
            nowDegree = status.position
            lockstatusLB.text = status.isInLockRange ? "locked" : status.isInUnlockRange ? "unlocked" : "moved"
        }
    }
    
    var mechSetting: CHSesame2MechSettings? {
        didSet {
            guard let setting = mechSetting else {
                return
            }
            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition
            lockSetBtn.setTitle("\(setting.lockPosition)", for: .normal)
            unlockSetBtn.setTitle("\(setting.unlockPosition)", for: .normal)
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
        deviceStatus = status

        if(deviceStatus == .receiveBle){
            device.connect(){_ in}
        }
        
        
        if(deviceStatus.loginStatus() == .login){
            self.mechSetting = device.mechSetting
            self.mechStatus = device.mechStatus
        }
    }
    
    
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        DispatchQueue.main.async {
            self.mechStatus = status
            self.lockIntention.text = intention.description
        }
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
        deviceIDLB.text = sesame!.deviceId.uuidString
        powerLB.text = "power: \(sesame!.mechStatus?.getBatteryPrecentage() ?? 0) %"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
         dfuHelper?.abort()
         dfuHelper = nil
     }
}
