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
    // MARK: - Properties
    var sesame: CHSesame2?
    private var testErrors = [String]()
    
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
    var alertIndicator = UIAlertController(title: "Testing", message: "", preferredStyle: .alert)
    
    @IBOutlet weak var startTestButton: UIButton! {
        didSet {
            startTestButton.isSelected = false
        }
    }
    
    @IBOutlet weak var logView: UITextView! {
        didSet {
            logView.text = ""
        }
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
    
    var deviceStatus: CHSesame2Status = CHSesame2Status.noBleSignal {
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
    
    lazy private var formate: DateFormatter = {
        let formate = DateFormatter()
        formate.dateFormat = "YYYY/MM/dd HH:mm:ss.SSS"
        formate.timeZone = .autoupdatingCurrent
        return formate
    }()
    
    var lockStatus: ((CHSesame2Intention) -> Void)?
}

// MARK: - Life Cycle
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if sesame!.deviceStatus.loginStatus() == .logined {
            startTest(startTestButton!)
        }
    }
    
    func toggle(_ completion: (()->Void)? = nil) {
        appendLog("toggle")
        
        lockStatus = { [weak self] intention in
            self?.alertIndicator.message = intention.description
            if intention == .idle {
                self?.lockStatus = nil
                completion?()
            }
        }
        
        sesame!.toggle { _ in
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
         dfuHelper?.abort()
         dfuHelper = nil
     }
}

// MARK: - IBActions
extension BluetoothSesame2ControlViewController {
    @IBAction func lockdegree(_ sender: Any) {
        lockDegree = nowDegree
    }
    
    @IBAction func startTest(_ sender: Any) {
        if (sender as? UIButton)?.isSelected == false {
            (sender as? UIButton)?.setTitle("Stop Test", for: .normal)
            (sender as? UIButton)?.isSelected = true
            
            testErrors = []
            
            present(alertIndicator, animated: true, completion: nil)
            
            appendLog("----------Test Start----------")
            appendLog(sesame!.deviceId.uuidString)
            
            toggle { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.toggle {
                    strongSelf.startTest(strongSelf.startTestButton!)
                }
            }
            
        } else {
            alertIndicator.dismiss(animated: true, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.appendLog(strongSelf.sesame!.deviceId.uuidString)
                strongSelf.appendLog("----------Test End----------")
                (sender as? UIButton)?.setTitle("Start Test", for: .normal)
                (sender as? UIButton)?.isSelected = false
                
                if strongSelf.testErrors.count > 0 {
                    strongSelf.completeFailedHandler()
                } else {
                    strongSelf.completeSucceedHandler()
                }
            })
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
            sesame!.connect() { [weak self] res in
                switch res {
                case .success(_):
                    break
                case .failure(let error):
                    self?.appendLog("connectClick \(error.errorDescription())")
                }
            }
        }
        
        @IBAction func disConnect(_ sender: Any) {
            appendLog("disconnect")
            sesame!.disconnect() { [weak self] res in
                switch res {
                case .success(_):
                    self?.appendLog("disconnect: succeed")
                case .failure(let error):
                    self?.appendLog("disconnect: \(error)")
                }
            }
        }
        
        @IBAction func registerBtn(_ sender: Any) {
            sesame!.registerSesame2(){ _ in}
        }
        @IBAction func cleanLog(_ sender: Any) {
            let cleanLog = UIAlertController(title: "Clean Log", message: nil, preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
                self?.logView.text = ""
            }
            cleanLog.addAction(ok)
            cleanLog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(cleanLog, animated: true, completion: nil)
        }
        
        @IBAction func share(_ sender: Any) {
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let formate = DateFormatter()
            formate.dateFormat = "YYYY_MM_dd_HH_mm_ss"
            formate.timeZone = .autoupdatingCurrent
            
            let fileURL = dir.appendingPathComponent("\(formate.string(from: Date()))_\(sesame!.deviceId.uuidString)_test_error.txt")
//            writeContent(logView.text, toFile: fileURL)
            let errorMessage = self.testErrors.reduce("") { (result, current) -> String in
                result + "\n\(current)"
            }
            writeContent(errorMessage, toFile: fileURL)
            shareFile(fileURL)
        }
}

// MARK: - Logic
extension BluetoothSesame2ControlViewController {
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
    
    private func completeSucceedHandler() {
        let alertController = UIAlertController(title: "Test Succeed", message: "Reset and Exit", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Reset and Exit", style: .default) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            ViewHelper.showLoadingInView(view: strongSelf.view)
            strongSelf.sesame!.resetSesame2 { result in
                switch result {
                case .success(_):
                    strongSelf.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    strongSelf.appendLog("Reset Sesame2: \(error)")
                }
            }
        }
        let testAgain = UIAlertAction(title: "Again", style: .default) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startTest(strongSelf.startTestButton!)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.addAction(testAgain)
        
        sesame!.getVersionTag { result in
            switch result {
            case .success(let status):
                DispatchQueue.main.async {
                    alertController.message = "\(status.data)\nReset and Exit"
                }
            case .failure(_):
                break
            }
        }
            
        present(alertController, animated: true, completion: {
    //            guard let strongSelf = self else {
    //                return
    //            }
    //            ViewHelper.showLoadingInView(view: strongSelf.view)
    //            strongSelf.appendLog("resetSesame2")
    //            strongSelf.sesame!.resetSesame2(){ res in
    //                ViewHelper.hideLoadingView(view: strongSelf.view)
    //                switch res {
    //                case .success(_):
    //                    strongSelf.testErrors.append("Reset Sesame2 succeed")
    //                    alertController.dismiss(animated: true) {
    //                        strongSelf.navigationController?.popViewController(animated: true)
    //                    }
    //                case .failure(let error):
    //                    strongSelf.testErrors.append("Reset Sesame2 failed \(error.errorDescription())")
    //                    strongSelf.completeFailedHandler()
    //                }
    //            }
        })
        
    }
    
    private func completeFailedHandler() {
        let errorMessage = self.testErrors.reduce("") { (result, current) -> String in
            result + "\n\(current)"
        }
        
        let alertController = UIAlertController(title: "",
                                                message: errorMessage,
                                                preferredStyle: .alert)
        
        let attributedString = NSAttributedString(string: "Test Failed", attributes: [
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor : UIColor.red
        ])
        
        alertController.setValue(attributedString, forKey: "attributedTitle")
        
        let ok = UIAlertAction(title: "Reset and Exit", style: .default) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            ViewHelper.showLoadingInView(view: strongSelf.view)
            strongSelf.unregisterClick(UIButton())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                strongSelf.navigationController?.popViewController(animated: true)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let share = UIAlertAction(title: "Share", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.share("")
        })
        let testAgain = UIAlertAction(title: "Again", style: .default) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startTest(strongSelf.startTestButton!)
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.addAction(share)
        alertController.addAction(testAgain)
        
        present(alertController, animated: true, completion: nil)
        
        testErrors = []
    }
}

// MARK: - Utilities
extension BluetoothSesame2ControlViewController {
    
    private func appendLog(_ log: String) {
            let currentTime = formate.string(from: Date())
            self.logView.text = "\n \(currentTime): \(log)" + self.logView.text
    //        let bottom = NSMakeRange(logView.text.count - 1, 1)
    //        logView.scrollRangeToVisible(bottom)
    }
    
    private func appendErrorLog(_ error: String) {
        let currentTime = formate.string(from: Date())
        let id = sesame!.deviceId.uuidString
        testErrors.append("\(id) - \(currentTime): \(error)")
    }

    func writeContent(_ content: String, toFile file: URL) {
        do {
            try content.write(to: file, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
    }
    
    func shareFile(_ file: URL) {
        let objectsToShare = [file]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
        let excludedActivities: [UIActivity.ActivityType] = [
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.message,
            UIActivity.ActivityType.mail,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.copyToPasteboard,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]
        activityViewController.excludedActivityTypes = excludedActivities
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            try? FileManager.default.removeItem(at: file)
        }
        present(activityViewController, animated: true, completion: nil)
    }
}

// MARK: - CHSesame2 Delegate
extension BluetoothSesame2ControlViewController {
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        deviceStatus = status

        if(deviceStatus == .receivedBle){
            device.connect(){_ in}
        }
        
        if(deviceStatus.loginStatus() == .logined){
            self.mechSetting = device.mechSetting
            self.mechStatus = device.mechStatus
        }
    }
    
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        DispatchQueue.main.async {
            self.mechStatus = status
            self.lockIntention.text = intention.description
            if let retCodetype = self.mechStatus?.retCodeType(),
                let isClutchFailed = self.mechStatus?.isClutchFailed {
                self.appendLog("retCodeType \(retCodetype.description)")
                self.appendLog("isClutchFailed \(isClutchFailed.description)")
                self.lockStatus?(device.intention)
                if retCodetype != .none && retCodetype != .success {
                    self.appendErrorLog(retCodetype.description)
                }
                if isClutchFailed == true {
                    self.appendErrorLog("clutchFailed")
                }
            }
        }
    }
}
