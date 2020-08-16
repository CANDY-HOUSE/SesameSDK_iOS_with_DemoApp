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
    private var isHiddenAutoLockSecondPicker = true
    private(set) var advIntervalTitle = "Adv Interval"
    private(set) var txPowerTitle = "TX Power"
    private(set) var advInterval = ""
    private(set) var txPower: String = ""
    
    private(set) var isHiddenAdvIntervalPicker = true
    private(set) var isHiddenTxPowerPicker = true
    
    public var statusUpdated: ViewStatusHandler?
    
    private var dfuHelper: DFUHelper?
    
    var delegate: Sesame2SettingViewModelDelegate?
    
    // MARK: - Properties
    private(set) var changeNameIndicator = "co.candyhouse.sesame-sdk-test-app.ChangeSesameName".localized
    private(set) var enterSesameName = "co.candyhouse.sesame-sdk-test-app.EnterSesameName".localized
    private(set) var angleIndicator = "co.candyhouse.sesame-sdk-test-app.ConfigureAngles".localized
    private(set) var dfuIndicator = "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized
    private(set) var removeSesameText = "co.candyhouse.sesame-sdk-test-app.ResetSesame".localized
    private(set) var dropKeyText = "co.candyhouse.sesame-sdk-test-app.TrashTheKey".localized
    private(set) var autoLockTitleLabelText = "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
    private(set) var autoLockValueLabelText = ""
    private(set) var arrowImg = "arrow"
    private(set) var uuidTitleText = "UUID".localized
    private(set) var modifyHistoryTagText = "History Tag".localized
    private(set) var mySesameText = "ドラえもん".localized
    private(set) var share = "co.candyhouse.sesame-sdk-test-app.ShareTheKey".localized
    private(set) var autoLockSwitchColor = UIColor.sesame2Green
    private(set) var advIntervalPickerSelectedRow: Int = 0
    private(set) var txPowerPickerSelectedRow: Int = 0
    private(set) var secondPickerSelectedRow: Int = 0
    
    var title: String {
        let device = Sesame2Store.shared.getPropertyForDevice(sesame2)
        return device.name ?? device.deviceID!.uuidString
    }
    
    var uuidValueText: String {
        sesame2.deviceId.uuidString
    }
    
    var autolockSwitchIsEnabled: Bool {
        sesame2.deviceStatus.loginStatus() == .logined
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
    
    var isAutoLockTitleLabelHidden: Bool {
        false
    }
    
    var isAutoLockValueLabelHidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isAutoLockLabel3Hidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isHiddenSecondPicker: Bool {
        isHiddenAutoLockSecondPicker
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
        getBleAdvParameter()
        isHiddenAutoLockSecondPicker = true
        sesame2.delegate = self
    }
    
    public func viewDidDisappear() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    @objc func updateUI() {
        executeOnMainThread {
            self.statusUpdated?(.update(nil))
        }
    }
    
    @objc func autoLockSwitchChanged(sender: UISwitch) {
        if !sender.isOn {
            sesame2.disableAutolock() { [weak self] (result) -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.statusUpdated?(.update(nil))
            }
            isHiddenAutoLockSecondPicker = true
        } else {
            isHiddenAutoLockSecondPicker = false
        }
        switchIsOn = sender.isOn
        statusUpdated?(.update(nil))
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
                strongSelf.isHiddenAutoLockDisplay = !strongSelf.switchIsOn
                strongSelf.delay = delay.data
                strongSelf.autoLockValueLabelText = String(format: "co.candyhouse.sesame-sdk-test-app.secAfter".localized, arguments: [strongSelf.formatedTimeFromSec(strongSelf.delay)])
                strongSelf.secondPickerSelectedRow = strongSelf.seconds.firstIndex(of: strongSelf.delay) ?? 0
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
                strongSelf.statusUpdated?(.update(nil))
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    private func getBleAdvParameter() {
        sesame2.getBleAdvParameter { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let bleAdvResult):
                let selectedAdvIntervalIndex = strongSelf.advIntervals.firstIndex(of: bleAdvResult.data.interval)
                strongSelf.advIntervalPickerSelectedRow = selectedAdvIntervalIndex ?? 0
                strongSelf.advInterval = strongSelf.readableAdvInterval(bleAdvResult.data.interval)
                strongSelf.txPower = strongSelf.readableTxPower(bleAdvResult.data.txPower)
                let selectedTxPowerIndex = strongSelf.dBms.firstIndex(of: Int(bleAdvResult.data.txPower))
                strongSelf.txPowerPickerSelectedRow = selectedTxPowerIndex ?? 0
                strongSelf.statusUpdated?(.update(nil))
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func readableAdvInterval(_ interval: Double) -> String {
        "\(interval) ms"
    }
    
    func readableTxPower(_ txPower: Int8) -> String {
        // -40dBm, -20dBm, -16dBm, -12dBm, -8dBm, -4dBm, 0dBm, +3dBm and +4dBm
        // 4 , 3 , 0 , -4 , -8 , -12 , -16 , -20 , -40
        
        guard let index = dBms.firstIndex(of: Int(txPower)) else {
            return "Unknow"
        }
        let value = dBms[index]
        if value > 0 {
            return "+\(value) dBm"
        } else {
            return "\(value) dBm"
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
            status == .receivedBle {
            device.connect(){_ in}
        }
    }
}

// MARK: - AutoLock
extension Sesame2SettingViewModel {
    private var seconds: [Int] {
        [3, 5, 7, 10, 15, 30, 60, 60*2, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    private var dBms: [Int] {
        [-40, -20, -16, -12, -8, -4, 0, 3, 4]
    }
    
    private var advIntervals: [Double] {
         [20, 152.5, 211.25, 318.75, 417.5, 546.25, 760, 852.5, 1022.5, 1285]
    }

    func columnOfAutoLock() -> Int {
        1
    }
    
    func columnOfAdvInterval() -> Int {
        1
    }
    
    func columnOfTxPower() -> Int {
        1
    }
    
    func rowOfAutoLock() -> Int {
        seconds.count
    }
    
    func rowOfAdvInterval() -> Int {
        advIntervals.count
    }
    
    func rowOfTxPower() -> Int {
        dBms.count
    }
    
    func secondPickerTextForRow(_ row: Int) -> String {
        formatedTimeFromSec(seconds[row])
    }
    
    func formatedTimeFromSec(_ sec: Int) -> String {
        if sec > 0 && sec < 60 {
            return "\(sec) \("co.candyhouse.sesame-sdk-test-app.sec".localized)"
        } else if sec >= 60 && sec < 60*60 {
            return "\(sec/60) \("co.candyhouse.sesame-sdk-test-app.min".localized)"
        } else if sec >= 60*60 {
            return "\(sec/(60*60)) \("co.candyhouse.sesame-sdk-test-app.hour".localized)"
        } else {
            return "co.candyhouse.sesame-sdk-test-app.off".localized
        }
    }
    
    func advIntervalPickerTextForRow(_ row: Int) -> String {
        "\(advIntervals[row]) ms"
    }
    
    func txPowerPickerTextForRow(_ row: Int) -> String {
        String(dBms[row])
    }
    
    func autolockSecondTapped() {
        defer {
            statusUpdated?(.update(nil))
        }
        if delay == 0 {
            isHiddenAutoLockSecondPicker = true
            switchIsOn = false
            return
        } else {
            switchIsOn = true
            isHiddenAutoLockDisplay = false
        }
        isHiddenAutoLockSecondPicker.toggle()
    }
    
    func advIntervalConfigTapped() {
        guard sesame2.deviceStatus.loginStatus() == .logined else {
            return
        }

        isHiddenAdvIntervalPicker.toggle()
        statusUpdated?(.update(nil))
    }
    
    func txPowerConfgTapped() {
        guard sesame2.deviceStatus.loginStatus() == .logined else {
            return
        }
        
        isHiddenTxPowerPicker.toggle()
        statusUpdated?(.update(nil))
    }
    
    func secondPickerDidSelectRow(_ row: Int) {

        sesame2.enableAutolock(delay: seconds[row]) { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
                DispatchQueue.main.async {
                    strongSelf.delay = delay.data
                    strongSelf.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                    strongSelf.isHiddenAutoLockSecondPicker = true
                    strongSelf.autoLockValueLabelText = String(format: "co.candyhouse.sesame-sdk-test-app.secAfter".localized, arguments: [strongSelf.secondPickerTextForRow(row)])
                    strongSelf.secondPickerSelectedRow = row
                    strongSelf.statusUpdated?(.update(nil))
                }
            case .failure(let error):
                L.d(error.errorDescription())
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }

        }
    }
    
    func advPickerDidSelectRow(_ row: Int) {
        let newAdvInterval = advIntervals[row]
        sesame2.updateBleAdvParameter(interval: newAdvInterval,
                                      txPower: Int8(dBms[txPowerPickerSelectedRow])) { [weak self] result in
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        switch result {
                                        case .success(let bleAdvParameterData):
                                            strongSelf.advIntervalPickerSelectedRow = row
                                            strongSelf.advInterval = strongSelf.readableAdvInterval(bleAdvParameterData.data.interval)
                                            strongSelf.statusUpdated?(.update(nil))
                                        case .failure(let error):
                                            strongSelf.statusUpdated?(.finished(.failure(error)))
                                        }
        }
        isHiddenAdvIntervalPicker = true
    }
    
    func txPowerPickerDidSelectRow(_ row: Int) {
        let newTxPower = dBms[row]
        let interval = advIntervals[advIntervalPickerSelectedRow]
        sesame2.updateBleAdvParameter(interval: interval,
                                      txPower: Int8(newTxPower)) { [weak self] result in
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        switch result {
                                        case .success(let bleAdvParameterData):
                                            strongSelf.txPower = strongSelf.readableTxPower(bleAdvParameterData.data.txPower)
                                            strongSelf.txPowerPickerSelectedRow = row
                                            strongSelf.statusUpdated?(.update(nil))
                                        case .failure(let error):
                                            strongSelf.statusUpdated?(.finished(.failure(error)))
                                        }
                                        
        }
        isHiddenTxPowerPicker = true
    }
}

// MARK: - DFU
extension Sesame2SettingViewModel {
    public func dfuActionText() -> String {
        "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized
    }
    
    public func dfuFileName() -> String? {
        guard let filePath = Constant
            .resourceBundle
            .url(forResource: nil,
                 withExtension: ".zip") else {
                return nil
        }
        return filePath.lastPathComponent
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
        WatchKitFileTransfer.transferKeysToWatch()
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

// MARK: - Remove Sesame
extension Sesame2SettingViewModel {
    
    public func deleteSesameTitle() -> String {
        "co.candyhouse.sesame-sdk-test-app.ResetSesame".localized
    }
    
    public func deleteSeesameAction() {
        statusUpdated?(.loading)
        let sesame2 = self.sesame2
        let deleteComplete = {
            Sesame2Store.shared.deletePropertyAndHisotryForDevice(sesame2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.delegate?.sesame2Deleted()
            }
        }
        
        guard AWSMobileClient.default().isSignedIn == true else {
            sesame2.resetSesame2() { [weak self] result in
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
        
        sesame2.resetSesame2() { [weak self] result in
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
        Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
        sesame2.dropKey(){res in}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
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
