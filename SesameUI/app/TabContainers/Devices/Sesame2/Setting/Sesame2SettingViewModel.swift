//
//  Sesame2SettingViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClient

public final class Sesame2SettingViewModel: ViewModel {
    // Data
    private var sesame2: CHSesame2
    // Display
    private var delay = 0
    private var version = ""
    // Status
    private var isHiddenAutoLockDisplay = true
    private var switchIsOn = false {
        didSet {
            if switchIsOn == false {
                isHiddenAutoLockDisplay = true
            }
        }
    }
    private var isHiddenPicker = true
    
    public var statusUpdated: ViewStatusHandler?
    
    private var dfuHelper: DFUHelper?
    
    var delegate: Sesame2SettingViewModelDelegate?
    
    // MARK: - Properties
    private(set) var changeNameIndicator = "Change Sesame Name".localStr
    private(set) var enterSesameName = "Enter Sesame name".localStr
    private(set) var angleIndicator = "Configure Angles".localStr
    private(set) var dfuIndicator = "SesameOS Update".localStr
    private(set) var removeSesameText = "Reset the Sesame and trash the key".localStr
    private(set) var dropKeyText = "Trash the key of the Sesame".localStr
    private(set) var autoLockLabel1Text = "autolock".localStr
    private(set) var autoLockLabel2Text = "After".localStr
    private(set) var autoLockLabel3Text = "sec".localStr
    private(set) var arrowImg = "arrow"
    private(set) var uuidTitleText = "UUID".localStr
    private(set) var modifyHistoryTagText = "History Tag".localStr
    private(set) var mySesameText = "ドラえもん".localStr
    private(set) var share = "Share the key of the Sesame".localStr
    private(set) var autoLockSwitchColor = UIColor.sesame2Green
    
    var title: String {
        let device = Sesame2Store.shared.getPropertyForDevice(sesame2)
        return device.name ?? device.deviceID!.uuidString
    }
    
    var uuidValueText: String {
        sesame2.deviceId.uuidString
    }
    
    var autolockSwitchIsEnabled: Bool {
        sesame2.deviceStatus.loginStatus() == .login
    }
    
    var isAutoLockSwitchOn: Bool {
        switchIsOn
    }
    
    var autoLockDisplay: String {
        String(delay)
    }
    
    var isAutoLockSecondHidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isAutoLockLabel1Hidden: Bool {
        false
    }
    
    var isAutoLockLabel2Hidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isAutoLockLabel3Hidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var secondPickerIsHidden: Bool {
        isHiddenPicker
    }
    
    var sesame2VersionText: String {
        version
    }

    var autoLockSecondText: String {
        String(delay)
    }
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
        self.sesame2.connect(){_ in}
    }

    // MARK: - User interaction
    
    public func viewWillAppear() {
        getAutoLockSetting()
        getVersionTag()
        isHiddenPicker = true
        sesame2.delegate = self
    }
    
    public func viewDidDisappear() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    @objc func updateUI() {
        executeOnMainThread {
            self.statusUpdated?(.received)
        }
    }
    
    @objc func autoLockSwitchChanged(sender: UISwitch) {
        if !sender.isOn {
            sesame2.disableAutolock() { [weak self] (result) -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.statusUpdated?(.received)
            }
            isHiddenPicker = true
        } else {
            isHiddenPicker = false
        }
        switchIsOn = sender.isOn
        statusUpdated?(.received)
    }
    
    // MARK: - Business logic
    
    private func getAutoLockSetting() {
        sesame2.getAutolockSetting { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
                strongSelf.switchIsOn = delay.data != 0

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getVersionTag() {
        sesame2.getVersionTag { [weak self]  result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let status):
                strongSelf.version = status.data
                strongSelf.statusUpdated?(.received)
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
            
        }
    }
    
    deinit {
        L.d("Sesame2SettingViewModel deinit")
    }
}

// MARK: - Delegate
extension Sesame2SettingViewModel: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status) {
        if device.deviceId == sesame2.deviceId,
            status == .receiveBle {
            device.connect(){_ in}
        }
    }
}

// MARK: - AutoLock
extension Sesame2SettingViewModel {
    var second: [Int] {
        [1,2,3,4,5,6,7,8,9,10,11,12,13]
    }

    func numberOfComponents() -> Int {
        1
    }
    
    func numberOfRowInComponent() -> Int {
        return second.count
    }
    
    func pickerTextForRow(_ row: Int) -> String {
        String(second[row])
    }
    
    func autolockSecondTapped() {
        defer {
            statusUpdated?(.received)
        }
        if delay == 0 {
            isHiddenPicker = true
            switchIsOn = false
            return
        } else {
            switchIsOn = true
            isHiddenAutoLockDisplay = false
        }
        isHiddenPicker.toggle()
    }
    
    func pickerDidSelectRow(_ row: Int) {

        sesame2.enableAutolock(delay: second[row]) { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
                DispatchQueue.main.async {
                    strongSelf.delay = delay.data
                    strongSelf.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                    strongSelf.isHiddenPicker = true
                    strongSelf.statusUpdated?(.received)
                }
            case .failure(let error):
                L.d(error.errorDescription())
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }

        }
    }
}

// MARK: - DFU
extension Sesame2SettingViewModel {
    public func dfuActionText() -> String {
        "SesameOS Update".localStr
    }
    
    public func dfuActionWithObserver(_ observer: DFUHelperObserver) {
        guard let filePath = Constant
            .resourceBundle
            .url(forResource: nil,
                 withExtension: ".zip"),
            let zipData = try? Data(contentsOf: filePath) else {
                return
        }
        
        sesame2.updateFirmware { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    L.d("Request commad failed.")
                    return
                }
                L.d("Success.")
                strongSelf.dfuHelper = CHDFUHelper(peripheral: peripheral, zipData: zipData)
                strongSelf.dfuHelper?.observer = observer
                strongSelf.dfuHelper?.start()
            case .failure(let error):
                L.d(error.errorDescription())
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
            
        }
    }
    
    public func cancelDFU() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
}

// MARK: - Rename
extension Sesame2SettingViewModel {
    func renamePlaceholder() -> String {
        let device = Sesame2Store.shared.getPropertyForDevice(sesame2)
        return device.name ?? device.deviceID!.uuidString
    }
    
    func rename(_ name: String) {
        Sesame2Store.shared.savePropertyForDevice(sesame2, withProperties: ["name": name])
    }
    
    func historyTagPlaceholder() -> String {
        guard let historyTag = sesame2.getHistoryTag() else {
            return mySesameText
        }
        return String(data: historyTag, encoding: .utf8) ?? mySesameText
    }
    
    func modifyHistoryTag(_ historyTag: String) {
        guard let encodedHistoryTag = historyTag.data(using: .utf8) else {
            let error = NSError(domain: "", code: 0, userInfo: ["message":"Unsupported format"])
            statusUpdated?(.finished(.failure(error)))
            return
        }
        sesame2.setHistoryTag(encodedHistoryTag) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(_):
                strongSelf.statusUpdated?(.finished(.success(true)))
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
}

// MARK: - Friends
extension Sesame2SettingViewModel {
    
    public func deleteSesameTitle() -> String {
        "Reset the Sesame and trash the key".localStr
    }
    
    public func deleteSeesameAction() {
        statusUpdated?(.loading)
        let sesame2 = self.sesame2
        let deleteComplete = {
            Sesame2Store.shared.deletePropertyForDevice(sesame2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.delegate?.sesame2Deleted()
            }
        }
        
        guard AWSMobileClient.default().isSignedIn == true else {
            sesame2.resetSesame() { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(_):
                    deleteComplete()
                case .failure(let error):
                    strongSelf.statusUpdated?(.finished(.failure(error)))
                }
            }
            return
        }
        
        sesame2.resetSesame() { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(_):
                deleteComplete()
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func dropKey() {
        statusUpdated?(.loading)
        Sesame2Store.shared.deletePropertyForDevice(self.sesame2)
        sesame2.dropKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Sesame2Store.shared.deletePropertyForDevice(self.sesame2)
            self.delegate?.sesame2Deleted()
        }
    }
}

public protocol Sesame2SettingViewModelDelegate {
    func setAngleForSesame2(_ sesame2: CHSesame2)
    func shareSesame2Tapped(_ sesame2: CHSesame2)
    func sesame2Deleted()
}

// MARK: - Navigation
extension Sesame2SettingViewModel {
    func setAngleTapped() {
        delegate?.setAngleForSesame2(sesame2)
    }
    
    func shareSesame2Tapped() {
        delegate?.shareSesame2Tapped(sesame2)
    }
}
