//
//  Sesame2SettingViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClient

class Sesame2SettingViewController: CHBaseViewController {
    
    // MARK: - Data model
    var sesame2: CHSesame2!
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: Sesame2PlainSettingView!
    var angleSettingView: Sesame2ArrowSettingView!
    var changeNameView: Sesame2PlainSettingView!
    var dfuView: Sesame2PlainSettingView!
    var autoLockView: Sesame2TogglePickerSettingView!
    var advIntervalView: Sesame2ExpandableSettingView?
    var txPowerView: Sesame2ExpandableSettingView?
    var autoUnlockView: Sesame2TogglePickerSettingView?
    var gpsLocationView: Sesame2ArrowSettingView?
    var siriShortcutUnlockView: Sesame2ArrowSettingView?
    
    // MARK: - Flags
    private var isHiddenAdvIntervalPicker = true
    private var isHiddenTxPowerPicker = true
    private var isHiddenAutoLockDisplay = true
    
    // MARK: - Values for UI
    var version = ""
    var advInterval = ""
    var txPower = ""
    var autoLockValueLabelText = ""
    var secondPickerSelectedRow: Int = 0
    var advIntervalPickerSelectedRow: Int = 0
    var txPowerPickerSelectedRow: Int = 0
    var autoUnlockPickerSelectedRow: Int {
        guard let sesame2Property = Sesame2Store.shared.getSesame2Property(sesame2) else {
            return 0
        }
        let selectedRow = Int(sesame2Property.autoUnlockType - 1)
        return selectedRow > -1 ? selectedRow : 1
    }
    
    // MARK: - Callback
    var dismissHandler: (()->Void)?

    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill

        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        arrangeSubviews()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thick))
        // MARK: UUID
        uuidView = Sesame2SettingViewGenerator.plain()
        uuidView.title = "UUID".localized
        uuidView.value = sesame2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
        
        // MARK: Angle setting
        angleSettingView = Sesame2SettingViewGenerator.arrow { [unowned self] _ in
            self.navigateToAngleSettingView()
        }
        angleSettingView.title = "co.candyhouse.sesame-sdk-test-app.ConfigureAngles".localized
        contentStackView.addArrangedSubview(angleSettingView)
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
        
        // MARK: Change name
        changeNameView = Sesame2SettingViewGenerator.plain { [unowned self] _ in
            self.changeName()
        }
        changeNameView.title = "co.candyhouse.sesame-sdk-test-app.ChangeSesameName".localized
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
        
        // MARK: DFU
        dfuView = Sesame2SettingViewGenerator.plain { [unowned self] sender in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
            
            let confirmAction = UIAlertAction(title: DFUHelper.applicationDfuFileName()!,
                                              style: .default) { _ in
                executeOnMainThread {
                    let dfuAlertController = DFUAlertController.instanceWithSesame2(self.sesame2)
                    self.present(dfuAlertController, animated: true, completion: {
                        dfuAlertController.startDFU()
                    })
                }
            }
            chooseDFUModeAlertController.addAction(confirmAction)
            chooseDFUModeAlertController.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                                                 style: .cancel,
                                                                 handler: nil))
            if let popover = chooseDFUModeAlertController.popoverPresentationController {
                popover.sourceView = self.dfuView
                popover.sourceRect = self.dfuView.bounds
            }
            self.present(chooseDFUModeAlertController, animated: true, completion: nil)
        }
        dfuView.title = "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized
        dfuView.value = version
        contentStackView.addArrangedSubview(dfuView)
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
        
        // MARK: AutoLock
        autoLockView = Sesame2SettingViewGenerator.togglePicker() { [unowned self] sender in
            if let toggle = sender as? UISwitch,
               toggle.isOn == false {
                self.autoLockOff()
            }
        }
        autoLockView.title = "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
        autoLockView.pickerView.delegate = self
        autoLockView.pickerView.dataSource = self
        autoLockView.fold()
        contentStackView.addArrangedSubview(autoLockView)
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
        
        if CHConfiguration.shared.isDebugModeEnabled() {
            // MARK: ADV Interval
            advIntervalView = Sesame2SettingViewGenerator.expandable() { _ in

            }
            advIntervalView!.title = "Adv Interval"
            advIntervalView!.pickerView.delegate = self
            advIntervalView!.pickerView.dataSource = self
            advIntervalView!.fold()
            contentStackView.addArrangedSubview(advIntervalView!)
            contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
            
            // MARK: TxPower
            txPowerView = Sesame2SettingViewGenerator.expandable() { _ in

            }
            txPowerView!.title = "TX Power"
            txPowerView!.pickerView.delegate = self
            txPowerView!.pickerView.dataSource = self
            txPowerView!.fold()
            contentStackView.addArrangedSubview(txPowerView!)
            contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
            
            // MARK: AutoUnlock
            autoUnlockView = Sesame2SettingViewGenerator.togglePicker() { [unowned self] sender in
                switch sender {
                case _ as UIButton:
                    self.autoUnlockView!.switchView.isOn = self.isAutoUnlockSwitchOn()
                case _ as UISwitch:
                    if !self.autoUnlockView!.switchView.isOn {
                        self.autoUnlockOff()
                        self.gpsLocationView!.removeFromSuperview()
                        self.autoUnlockView!.pickerView.selectRow(0, inComponent: 0, animated: false)
                    }
                default:
                    break
                }
            }
            autoUnlockView!.title = "AutoUnlock"
            autoUnlockView!.pickerView.delegate = self
            autoUnlockView!.pickerView.dataSource = self
            autoUnlockView!.fold()
            contentStackView.addArrangedSubview(autoUnlockView!)
            contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thin))
            
            // MARK: GPS Location
            gpsLocationView = Sesame2SettingViewGenerator.arrow() { [unowned self] _ in
                let gpsLocationViewController = GPSMapViewController(nibName: nil, bundle: nil)
                gpsLocationViewController.sesame2 = self.sesame2
                self.navigationController?.pushViewController(gpsLocationViewController, animated: true)
            }
            gpsLocationView!.title = "GPS Location"
            
            // MARK: Siri Shortcut
            siriShortcutUnlockView = Sesame2SettingViewGenerator.arrow() { [unowned self] _ in
                let siriShortcutViewController = SiriShortCutViewController.instanceWithSesame2(self.sesame2)
                self.navigationController?.pushViewController(siriShortcutViewController, animated: true)
            }
            siriShortcutUnlockView!.title = "Siri Shortcut"
            contentStackView.addArrangedSubview(siriShortcutUnlockView!)
        }

        // MARK: Share
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thick))
        let shareKeyView = Sesame2SettingCallToActionView { [unowned self] sender in
            self.presentQRCodeSharingView()
        }
        shareKeyView.title = "co.candyhouse.sesame-sdk-test-app.ShareTheKey".localized
        contentStackView.addArrangedSubview(shareKeyView)

        // MARK: Drop key
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thick))
        let dropKeyView = Sesame2SettingCallToActionView(textColor: .red) { [unowned self] sender in
            self.trashKey(sender: sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame-sdk-test-app.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)

        // MARK: Reset Sesame
        contentStackView.addArrangedSubview(Sesame2SettingSeperatorView(style: .thick))
        let resetKeyView = Sesame2SettingCallToActionView(textColor: .red) { [unowned self] sender in
            self.confirmUnRegister(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame-sdk-test-app.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAutoLockSetting()
        getVersionTag()
        getBleAdvParameter()
        sesame2.delegate = self
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        title = device?.name ?? sesame2.deviceId.uuidString
    }
    
    // MARK: - Methods
    
    
    
    // MARK: RefreshUI
    func refreshUI() {
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        title = device?.name ?? sesame2.deviceId.uuidString
        
        autoLockView.switchView.isOn = !isHiddenAutoLockDisplay
        autoLockView.switchView.isEnabled = sesame2.deviceStatus.loginStatus() == .logined
        autoLockView.button.isEnabled = sesame2.deviceStatus.loginStatus() == .logined
        autoLockView.value = isHiddenAutoLockDisplay ? "" : autoLockValueLabelText
        
        advIntervalView?.value = advInterval
        advIntervalView?.isPickerOn = !isHiddenAdvIntervalPicker
        
        txPowerView?.value = txPower
        txPowerView?.isPickerOn = !isHiddenTxPowerPicker
        
        autoUnlockView?.value = autoUnlockType()
        autoUnlockView?.switchView.isOn = isAutoUnlockSwitchOn()
        
        dfuView.value = version

        autoLockView.pickerView.selectRow(secondPickerSelectedRow, inComponent: 0, animated: false)
        advIntervalView?.pickerView.selectRow(advIntervalPickerSelectedRow, inComponent: 0, animated: false)
        txPowerView?.pickerView.selectRow(txPowerPickerSelectedRow, inComponent: 0, animated: false)
        autoUnlockView?.pickerView.selectRow(autoUnlockPickerSelectedRow, inComponent: 0, animated: false)
        
        if CHConfiguration.shared.isDebugModeEnabled() {
            if let sesame2Property = Sesame2Store.shared.getSesame2Property(sesame2) {
                switch Int(sesame2Property.autoUnlockType) {
                case AutoUnlockType.gps.rawValue:
                    contentStackView.insertArrangedSubview(gpsLocationView!, at: 16)
                default:
                    gpsLocationView!.removeFromSuperview()
                }
            } else {
                gpsLocationView!.removeFromSuperview()
            }
        }
    }
    
    // MARK: getAutoLockSetting
    func getAutoLockSetting() {
        sesame2.getAutolockSetting { result in
            switch result {
            case .success(let delay):
                self.isHiddenAutoLockDisplay = delay.data == 0
                self.autoLockValueLabelText = String(format: "co.candyhouse.sesame-sdk-test-app.secAfter".localized, arguments: [self.formatedTimeFromSec(delay.data)])
                self.secondPickerSelectedRow = self.seconds.firstIndex(of: delay.data) ?? 0
                executeOnMainThread {
                    self.refreshUI()
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: getVersionTag
    private func getVersionTag() {
        sesame2.getVersionTag { result in
            switch result {
            case .success(let status):
                self.version = status.data
                executeOnMainThread {
                    self.refreshUI()
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: getBleAdvParameter
    private func getBleAdvParameter() {
        sesame2.getBleAdvParameter { result in
            switch result {
            case .success(let bleAdvResult):
                let selectedAdvIntervalIndex = self.advIntervals.firstIndex(of: bleAdvResult.data.interval)
                self.advIntervalPickerSelectedRow = selectedAdvIntervalIndex ?? 0
                self.advInterval = self.readableAdvInterval(bleAdvResult.data.interval)
                self.txPower = self.readableTxPower(bleAdvResult.data.txPower)
                let selectedTxPowerIndex = self.dBms.firstIndex(of: Int(bleAdvResult.data.txPower))
                self.txPowerPickerSelectedRow = selectedTxPowerIndex ?? 0
                executeOnMainThread {
                    self.refreshUI()
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: changeName
    func changeName() {
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        let placeholder = device?.name ?? sesame2.deviceId.uuidString
        
        ChangeValueDialog.show(placeholder) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame-sdk-test-app.EnterSesameName".localized)
                return
            }
            Sesame2Store.shared.savePropertyToDevice(self.sesame2, withProperties: ["name": name])
            WatchKitFileTransfer.transferKeysToWatch()
            self.refreshUI()
        }
    }
    
    // MARK: autoLockOff
    func autoLockOff() {
        sesame2.enableAutolock(delay: 0) { result  in
            switch result {
            case .success(_):
                executeOnMainThread {
                    self.isHiddenAutoLockDisplay = true
                    self.refreshUI()
                }
            case .failure(let error):
                L.d(error.errorDescription())
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: isAutoUnlockSwitchOn
    func isAutoUnlockSwitchOn() -> Bool {
        guard let sesame2Property = Sesame2Store.shared.getSesame2Property(sesame2) else {
            return false
        }
        switch sesame2Property.autoUnlockType {
        case 0:
            return false
        case 1:
            return true
        case 2:
            return true
        default:
            return false
        }
    }
    
    // MARK: autoUnlockOff
    func autoUnlockOff() {
        Sesame2Store.shared.saveAutoUnlockForSesame2(sesame2, type: .off)
        BackgroundLockManager.activeIfNeeded()
        refreshUI()
    }
    
    // MARK: navigateToAngleSettingView
    func navigateToAngleSettingView() {
        navigationController?.pushViewController(LockAngleSettingViewController.instanceWithSesame2(sesame2),
                                                 animated: true)
    }
    
    // MARK: presentQRCodeSharingView
    func presentQRCodeSharingView() {
        DispatchQueue.main.async {
            let sesame2QRCodeViewController = Sesame2QRCodeViewController.instanceWithSesame2(self.sesame2)
            self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
        }
    }
    
    // MARK: trashKey
    func trashKey(sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.TrashTheKey".localized,
                                            style: .destructive) { (action) in
                                                ViewHelper.showLoadingInView(view: self.view)
                                                Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
                                                self.sesame2.dropKey() { _ in }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    ViewHelper.hideLoadingView(view: self.view)
                                                    Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
                                                    self.navigationController?.popToRootViewController(animated: true)
                                                    self.dismissHandler?()
                                                }
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                            style: .cancel) { (action) in
            
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    func confirmUnRegister(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.ResetSesame".localized,
                      style: .destructive) { _ in
            self.unregisterSesame2()
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                            style: .cancel) { (action) in
            
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(unregister)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: unregisterSesame2
    public func unregisterSesame2() {
        ViewHelper.showLoadingInView(view: view)
        let sesame2 = self.sesame2
        let deleteComplete = {
            Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ViewHelper.hideLoadingView(view: self.view)
                Sesame2Store.shared.deletePropertyAndHisotryForDevice(self.sesame2)
                self.navigationController?.popToRootViewController(animated: true)
                self.dismissHandler?()
            }
        }
        
        guard AWSMobileClient.default().isSignedIn == true else {
            sesame2?.resetSesame2() { result in
                switch result {
                case .success(_):
                    deleteComplete()
                case .failure(let error):
                    self.view.makeToast(error.errorDescription())
                }
            }
            return
        }
        
        sesame2?.resetSesame2() { result in
            switch result {
            case .success(_):
                deleteComplete()
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    func autoUnlockType() -> String {
        guard let sesame2Property = Sesame2Store.shared.getSesame2Property(sesame2) else {
            return ""
        }
        switch sesame2Property.autoUnlockType {
        case 0:
            return ""
        case 1:
            return "by GPS"
        case 2:
            return "by Background Ble"
        default:
            return "unknow"
        }
    }
}

// MARK: - CHSesame2Delegate
extension Sesame2SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status,
                                         shadowStatus: CHSesame2ShadowStatus?) {
        if device.deviceId == sesame2.deviceId,
            status == .receivedBle {
            device.connect() { _ in }
        }
    }
}

// MARK: - TableView data source and delegate
extension Sesame2SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    private var seconds: [Int] {
        [3, 5, 7, 10, 15, 30, 60, 60*2, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    private var dBms: [Int] {
        [-40, -20, -16, -12, -8, -4, 0, 3, 4]
    }
    
    private var advIntervals: [Double] {
         [20, 152.5, 211.25, 318.75, 417.5, 546.25, 760, 852.5, 1022.5, 1285]
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch pickerView {
        case autoLockView.pickerView:
            return 1
        case advIntervalView!.pickerView:
            return 1
        case txPowerView!.pickerView:
            return 1
        case autoUnlockView!.pickerView:
            return 1
        default:
            return 0
        }
    }

    // MARK: UIPickerViewDataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case autoLockView.pickerView:
            return seconds.count
        case advIntervalView!.pickerView:
            return advIntervals.count
        case txPowerView!.pickerView:
            return dBms.count
        case autoUnlockView!.pickerView:
            return 2
        default:
            return 0
        }
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        
        switch pickerView {
        case autoLockView.pickerView:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = formatedTimeFromSec(seconds[row])
            }
            return pickerLabel!
        case advIntervalView!.pickerView:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = advIntervalPickerTextForRow(row)
            }
            return pickerLabel!
        case txPowerView!.pickerView:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = txPowerPickerTextForRow(row)
            }
            return pickerLabel!
        case autoUnlockView!.pickerView:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                if row == 0 {
                    pickerLabel?.text = "by GPS"
                } else {
                    pickerLabel?.text = "by background Ble"
                }
            }
            return pickerLabel!
        default:
            return UIView()
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case autoLockView.pickerView:
            autoLockView.fold()
            autoLockView.switchView.isOn = true
            secondPickerDidSelectRow(row)
        case advIntervalView!.pickerView:
            advPickerDidSelectRow(row)
        case txPowerView!.pickerView:
            txPowerPickerDidSelectRow(row)
        case autoUnlockView!.pickerView:
            autoUnlockView!.fold()
            autoUnlockView!.switchView.isOn = true
            autoUnlockSelected(row)
        default:
            break
        }
    }
    
    // MARK: formatedTimeFromSec
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
    
    // MARK: advIntervalPickerTextForRow
    func advIntervalPickerTextForRow(_ row: Int) -> String {
        "\(advIntervals[row]) ms"
    }
    
    // MARK: txPowerPickerTextForRow
    func txPowerPickerTextForRow(_ row: Int) -> String {
        String(dBms[row])
    }
    
    // MARK: secondPickerDidSelectRow
    func secondPickerDidSelectRow(_ row: Int) {

        sesame2.enableAutolock(delay: seconds[row]) { result  in
            switch result {
            case .success(let delay):
                self.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                self.autoLockValueLabelText = String(format: "co.candyhouse.sesame-sdk-test-app.secAfter".localized, arguments: [self.formatedTimeFromSec(self.seconds[row])])
                self.secondPickerSelectedRow = row
                executeOnMainThread {
                    self.refreshUI()
                }
            case .failure(let error):
                L.d(error.errorDescription())
                self.view.makeToast(error.errorDescription())
            }

        }
    }
    
    // MARK: advPickerDidSelectRow
    func advPickerDidSelectRow(_ row: Int) {
        let newAdvInterval = advIntervals[row]
        sesame2.updateBleAdvParameter(interval: newAdvInterval,
                                      txPower: Int8(dBms[txPowerPickerSelectedRow])) { result in
                                        switch result {
                                        case .success(let bleAdvParameterData):
                                            self.advIntervalPickerSelectedRow = row
                                            self.advInterval = self.readableAdvInterval(bleAdvParameterData.data.interval)
                                            executeOnMainThread {
                                                self.refreshUI()
                                            }
                                        case .failure(let error):
                                            self.view.makeToast(error.errorDescription())
                                        }
        }
        isHiddenAdvIntervalPicker = true
    }
    
    // MARK: txPowerPickerDidSelectRow
    func txPowerPickerDidSelectRow(_ row: Int) {
        let newTxPower = dBms[row]
        let interval = advIntervals[advIntervalPickerSelectedRow]
        sesame2.updateBleAdvParameter(interval: interval,
                                      txPower: Int8(newTxPower)) { result in
                                        switch result {
                                        case .success(let bleAdvParameterData):
                                            self.txPower = self.readableTxPower(bleAdvParameterData.data.txPower)
                                            self.txPowerPickerSelectedRow = row
                                            executeOnMainThread {
                                                self.refreshUI()
                                            }
                                        case .failure(let error):
                                            self.view.makeToast(error.errorDescription())
                                        }
                                        
        }
        isHiddenTxPowerPicker = true
    }
    
    // MARK: readableTxPower
    func readableTxPower(_ txPower: Int8) -> String {
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
    
    // MARK: readableAdvInterval
    func readableAdvInterval(_ interval: Double) -> String {
        "\(interval) ms"
    }
    
    // MARK: autoUnlockSelected
    func autoUnlockSelected(_ row: Int) {
        Sesame2Store.shared.saveAutoUnlockForSesame2(sesame2, type: AutoUnlockType(rawValue: row + 1)!)
        BackgroundLockManager.activeIfNeeded()
        refreshUI()
    }
}

// MARK: - Designated initializer
extension Sesame2SettingViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2, dismissHandler: (()->Void)? = nil) -> Sesame2SettingViewController {
        let sesame2SettingViewController = Sesame2SettingViewController(nibName: nil, bundle: nil)
        sesame2SettingViewController.sesame2 = sesame2
        sesame2SettingViewController.dismissHandler = dismissHandler
        return sesame2SettingViewController
    }
}
