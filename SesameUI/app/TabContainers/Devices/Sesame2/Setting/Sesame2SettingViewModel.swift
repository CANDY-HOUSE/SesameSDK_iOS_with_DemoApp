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
    private(set) var autoLockLabel1Text = "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
    private(set) var autoLockLabel2Text = "co.candyhouse.sesame-sdk-test-app.after".localized
    private(set) var autoLockLabel3Text = "co.candyhouse.sesame-sdk-test-app.sec".localized
    private(set) var arrowImg = "arrow"
    private(set) var uuidTitleText = "UUID".localized
    private(set) var modifyHistoryTagText = "History Tag".localized
    private(set) var mySesameText = "ドラえもん".localized
    private(set) var share = "co.candyhouse.sesame-sdk-test-app.ShareTheKey".localized
    private(set) var autoLockSwitchColor = UIColor.sesame2Green
    
    private let dBms = [-40, -20, -16, -12, -8, -4, 0, 3, 4]
    private let advIntervals = [20, 152.5, 211.25, 318.75, 417.5, 546.25, 760, 852.5, 1022.5, 1285]
    private(set) var advIntervalPickerSelectedRow: Int = 0
    private(set) var txPowerPickerSelectedRow: Int = 0
    
    
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
            isHiddenAutoLockSecondPicker = true
        } else {
            isHiddenAutoLockSecondPicker = false
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
                strongSelf.isHiddenAutoLockDisplay = !strongSelf.switchIsOn
                strongSelf.delay = delay.data
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
    
    private func getBleAdvParameter() {
        sesame2.getBleAdvParameter { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let bleAdvResult):
                let selectedAdvIntervalIndex = strongSelf.advIntervals.firstIndex(of: strongSelf.millionsecondFromBleUnit(bleAdvResult.data.interval))
                strongSelf.advIntervalPickerSelectedRow = selectedAdvIntervalIndex ?? 0
                strongSelf.advInterval = strongSelf.readableAdvInterval(bleAdvResult.data.interval)
                strongSelf.txPower = strongSelf.readableTxPower(bleAdvResult.data.txPower)
                let selectedTxPowerIndex = strongSelf.dBms.firstIndex(of: Int(bleAdvResult.data.txPower))
                strongSelf.txPowerPickerSelectedRow = selectedTxPowerIndex ?? 0
                strongSelf.statusUpdated?(.received)
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func readableAdvInterval(_ interval: UInt16) -> String {
        "\(millionsecondFromBleUnit(interval)) ms"
    }
    
    func bleUnitFromMillionSecond(_ millionSecond: Double) -> Int {
        Int(millionSecond / 0.625)
    }
    
    func millionsecondFromBleUnit(_ bleUnit: UInt16) -> Double {
        Double(bleUnit) * 0.625
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
            status == .receiveBle {
            device.connect(){_ in}
        }
    }
}

// MARK: - AutoLock
extension Sesame2SettingViewModel {
    private var second: [Int] {
        [1,2,3,4,5,6,7,8,9,10,11,12,13]
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
        second.count
    }
    
    func rowOfAdvInterval() -> Int {
        advIntervals.count
    }
    
    func rowOfTxPower() -> Int {
        dBms.count
    }
    
    func secondPickerTextForRow(_ row: Int) -> String {
        String(second[row])
    }
    
    func advIntervalPickerTextForRow(_ row: Int) -> String {
        "\(advIntervals[row]) ms"
    }
    
    func txPowerPickerTextForRow(_ row: Int) -> String {
        String(dBms[row])
    }
    
    func autolockSecondTapped() {
        defer {
            statusUpdated?(.received)
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
//        guard sesame2.deviceStatus.loginStatus() == .login else {
//            return
//        }
//
//        isHiddenAdvIntervalPicker.toggle()
//        statusUpdated?(.received)
    }
    
    func txPowerConfgTapped() {
//        guard sesame2.deviceStatus.loginStatus() == .login else {
//            return
//        }
//        
//        isHiddenTxPowerPicker.toggle()
//        statusUpdated?(.received)
    }
    
    func secondPickerDidSelectRow(_ row: Int) {

        sesame2.enableAutolock(delay: second[row]) { [weak self] result  in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let delay):
                DispatchQueue.main.async {
                    strongSelf.delay = delay.data
                    strongSelf.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                    strongSelf.isHiddenAutoLockSecondPicker = true
                    strongSelf.statusUpdated?(.received)
                }
            case .failure(let error):
                L.d(error.errorDescription())
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }

        }
    }
    
    func advPickerDidSelectRow(_ row: Int) {
//        let newAdvInterval = advIntervals[row]
//        sesame2.updateBleAdvParameter(interval: UInt16(bleUnitFromMillionSecond(newAdvInterval)),
//                                      txPower: sesame2.bleAdvParameter!.txPower) { [weak self] _ in
//                                        guard let strongSelf = self else {
//                                            return
//                                        }
//                                        strongSelf.advIntervalPickerSelectedRow = row
//                                        strongSelf.statusUpdated?(.received)
//        }
        isHiddenAdvIntervalPicker = true
    }
    
    func txPowerPickerDidSelectRow(_ row: Int) {
//        let newTxPower = dBms[row]
//        sesame2.updateBleAdvParameter(interval: sesame2.bleAdvParameter!.interval,
//                                      txPower: Int8(newTxPower)) { [weak self] _ in
//                                        guard let strongSelf = self else {
//                                            return
//                                        }
//                                        strongSelf.txPowerPickerSelectedRow = row
//                                        strongSelf.statusUpdated?(.received)
//        }
        isHiddenTxPowerPicker = true
    }
}

// MARK: - DFU
extension Sesame2SettingViewModel {
    public func dfuActionText() -> String {
        "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized
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
