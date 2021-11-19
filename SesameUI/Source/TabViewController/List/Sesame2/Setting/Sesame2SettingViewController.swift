//
//  Sesame2SettingViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import iOSDFULibrary
import CoreBluetooth

class Sesame2SettingViewController: CHBaseViewController {
    // MARK: - Data model
    var sesame2: CHSesame2!
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    var statusView: CHUIPlainSettingView!
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var angleSettingView: CHUIArrowSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var autoLockView: CHUITogglePickerSettingView!
    
    // MARK: - Flags
    private var isHiddenAdvIntervalPicker = true
    private var isHiddenTxPowerPicker = true
    private var isHiddenAutoLockDisplay = true
    
    // MARK: - Values for UI
    var version: String? {
        didSet {
            guard version != nil else {
                return
            }
            executeOnMainThread {
                self.refreshUI()
            }
        }
    }
    var autoLock: Int? {
        didSet {
            guard autoLock != nil else {
                return
            }
            executeOnMainThread {
                self.isHiddenAutoLockDisplay = self.autoLock == 0
                self.autoLockValueLabelText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [self.formatedTimeFromSec(self.autoLock!)])
                self.secondPickerSelectedRow = self.seconds.firstIndex(of: self.autoLock!) ?? 0
                self.refreshUI()
            }
        }
    }
    var autoLockValueLabelText = ""
    var secondPickerSelectedRow: Int = 0
    var isReset: Bool = false
    // MARK: - Callback
    var dismissHandler: ((_ isReset: Bool)->Void)?
    
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
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: sesame2)
        showStatusViewIfNeeded()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            self.changeName()
        }
        changeNameView.title = "co.candyhouse.sesame2.EditSesameName".localized
        changeNameView.value = sesame2.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
            self.presentQRCodeSharingView(sender: sender as! UIButton)
        }
        shareKeyView.title = "co.candyhouse.sesame2.ShareTheKey".localized
        contentStackView.addArrangedSubview(shareKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Angle setting
        angleSettingView = CHUIViewGenerator.arrow { [unowned self] _,_ in
            self.navigateToAngleSettingView()
        }
        angleSettingView.title = "co.candyhouse.sesame2.ConfigureAngles".localized
        contentStackView.addArrangedSubview(angleSettingView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: AutoLock
        autoLockView = CHUIViewGenerator.togglePicker() { [unowned self] sender,_ in
            if self.secondPickerSelectedRow != 0 {
                self.autoLockOff()
            }
        }
        autoLockView.title = "co.candyhouse.sesame2.AutoLock".localized
        autoLockView.pickerView.delegate = self
        autoLockView.pickerView.dataSource = self
        autoLockView.fold()
        contentStackView.addArrangedSubview(autoLockView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
            
            let confirmAction = UIAlertAction(title: DFUHelper.sesame2ApplicationDfuFileName(sesame2),
                                              style: .default) { _ in
                self.dfuSesame2(self.sesame2)
            }
            chooseDFUModeAlertController.addAction(confirmAction)
            chooseDFUModeAlertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                                                 style: .cancel,
                                                                 handler: nil))
            if let popover = chooseDFUModeAlertController.popoverPresentationController {
                popover.sourceView = self.dfuView
                popover.sourceRect = self.dfuView.bounds
            }
            self.present(chooseDFUModeAlertController, animated: true, completion: nil)
        }
        dfuView.title = "co.candyhouse.sesame2.SesameOSUpdate".localized
        dfuView.value = version ?? ""
        contentStackView.addArrangedSubview(dfuView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: UUID
        uuidView = CHUIViewGenerator.plain { [unowned self] _,_ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = uuidView.value
        }
        uuidView.title = "UUID".localized
        uuidView.value = sesame2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.dropKey(sender: sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop Key Desc
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized])
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 3
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop()
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        #if DEBUG
        // MARK: Reset Sesame
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.confirmReset(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAutoLockSetting()
        getVersionTag()
        sesame2.delegate = self
        if sesame2.deviceStatus == .receivedBle() {
            sesame2.connect() { _ in }
        }
        refreshUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            DFUCenter.shared.removeDFUDelegateForDevice(sesame2)
            dismissHandler?(isReset)
        }
    }

    // MARK: RefreshUI
    func refreshUI() {
        autoLockView.switchView.isOn = !isHiddenAutoLockDisplay
        autoLockView.switchView.isEnabled = sesame2.deviceStatus.loginStatus == .logined
        autoLockView.button.isEnabled = sesame2.deviceStatus.loginStatus == .logined
        autoLockView.value = isHiddenAutoLockDisplay ? "" : autoLockValueLabelText
        dfuView.value = version ?? ""
        autoLockView.pickerView.selectRow(secondPickerSelectedRow, inComponent: 0, animated: false)
        changeNameView.value = sesame2.deviceName
    }
    
    // MARK: getAutoLockSetting
    func getAutoLockSetting() {
        sesame2.getAutolockSetting { result in
            switch result {
            case .success(let delay):
                self.autoLock = delay.data
            case .failure(let error):
                L.d(error.errorDescription())
                if self.sesame2.deviceStatus.loginStatus == .logined {
                    self.view.makeToast("getAutoLockSetting failed \(error.errorDescription())")
                }
            }
        }
    }
    
    // MARK: getVersionTag
    private func getVersionTag() {
        sesame2.getVersionTag { result in
            switch result {
            case .success(let status):
                self.version = status.data
            case .failure(let error):
                L.d(error.errorDescription())
            }
        }
    }
    
    // MARK: changeName
    func changeName() {
        let placeholder = sesame2.deviceName
        
        ChangeValueDialog.show(placeholder, title: "co.candyhouse.sesame2.EditSesameName".localized) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame2.EditSesameName".localized)
                return
            }
            self.sesame2.setDeviceName(name)
            WatchKitFileTransfer.shared.transferKeysToWatch()
            self.refreshUI()
            
            if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                listViewController.reloadTableView()
            }
        }
    }
    
    // MARK: autoLockOff
    func autoLockOff() {
        secondPickerSelectedRow = 0
        sesame2.enableAutolock(delay: 0) { result  in
            switch result {
            case .success(_):
                executeOnMainThread {
                    self.isHiddenAutoLockDisplay = true
                    self.refreshUI()
                }
            case .failure(let error):
                L.d(error.errorDescription())
            }
        }
    }
    
    // MARK: navigateToAngleSettingView
    func navigateToAngleSettingView() {
        navigationController?.pushViewController(LockAngleSettingViewController.instanceWithSesame2(sesame2),
                                                 animated: true)
    }
    
    // MARK: presentQRCodeSharingView
    func presentQRCodeSharingView(sender: UIButton) {
        executeOnMainThread {
            let deviceKey = self.sesame2.getKey()
            let qrCode = URL.qrCodeURLFromDeviceKey(deviceKey!, deviceName: self.sesame2.deviceName)
            let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesame2, qrCode: qrCode!)
            self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
        }
    }
    
    // MARK: OTA
    func dfuSesame2(_ sesame2: CHSesame2) {
        DFUCenter.shared.dfuDevice(sesame2, delegate: self)
        self.version = nil
    }
    
    // MARK: dropKey
    func dropKey(sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.TrashTheKey".localized,
                                            style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            Sesame2Store.shared.deletePropertyFor(self.sesame2)
            self.sesame2.dropKey() { _ in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.isReset = true
                    self.navigationController?.popToRootViewController(animated: false)
                }
            }
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                      style: .destructive) { _ in
            self.resetSesame2()
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                            style: .cancel) { (action) in
            
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(unregister)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: unregisterSesame2
    func resetSesame2() {
        ViewHelper.showLoadingInView(view: view)
        Sesame2Store.shared.deletePropertyFor(self.sesame2)
        self.sesame2.reset { resetResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
    }
    
    func showStatusViewIfNeeded() {
        if CHBleManager.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if sesame2.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = sesame2.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
    }
}

// MARK: - CHSesame2Delegate
extension Sesame2SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesameLock,
                                         status: CHSesame2Status,
                                         shadowStatus: CHSesame2ShadowStatus?) {
        if device.deviceId == sesame2.deviceId,
            status == .receivedBle() {
            device.connect() { _ in }
        } else if status.loginStatus == .logined {
            if version == nil {
                getVersionTag()
            }
            if autoLock == nil {
                getAutoLockSetting()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
}

// MARK: - TableView data source and delegate
extension Sesame2SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    private var seconds: [Int] {
        [0, 3, 5, 7, 10, 15, 30, 60, 60*2, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    // MARK: UIPickerViewDataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        seconds.count
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        
        if pickerLabel == nil{
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16)
            pickerLabel?.textAlignment = .center
            pickerLabel?.text = formatedTimeFromSec(seconds[row])
        }
        return pickerLabel!
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        autoLockView.fold()
        secondPickerDidSelectRow(row)
    }
    
    // MARK: formatedTimeFromSec
    func formatedTimeFromSec(_ sec: Int) -> String {
        if sec > 0 && sec < 60 {
            return "\(sec) \("co.candyhouse.sesame2.sec".localized)"
        } else if sec >= 60 && sec < 60*60 {
            return "\(sec/60) \("co.candyhouse.sesame2.min".localized)"
        } else if sec >= 60*60 {
            return "\(sec/(60*60)) \("co.candyhouse.sesame2.hour".localized)"
        } else {
            return "co.candyhouse.sesame2.off".localized
        }
    }
    
    // MARK: secondPickerDidSelectRow
    func secondPickerDidSelectRow(_ row: Int) {
        ViewHelper.showLoadingInView(view: self.autoLockView)
        sesame2.enableAutolock(delay: seconds[row]) { result  in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.autoLockView)
                switch result {
                case .success(let delay):
                    self.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                    self.autoLockView.switchView.isOn = delay.data > 0
                    self.autoLockValueLabelText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [self.formatedTimeFromSec(self.seconds[row])])
                    self.secondPickerSelectedRow = row
                    self.refreshUI()
                case .failure(let error):
                    L.d(error.errorDescription())
                }
            }
        }
    }
}

// MARK: - DFUHelperDelegate
extension Sesame2SettingViewController: DFUHelperDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .starting:
            self.dfuView.value = "co.candyhouse.sesame2.StartingSoon".localized
        case .completed:
            self.dfuView.value = "co.candyhouse.sesame2.Succeeded".localized
        case .aborted:
            break
        default:
            break
        }
    }
    
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String) {
        view.makeToast(message)
    }
    
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        dfuView.value = "\(progress)%"
    }
}

// MARK: - Designated initializer
extension Sesame2SettingViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2, dismissHandler: ((Bool)->Void)? = nil) -> Sesame2SettingViewController {
        let sesame2SettingViewController = Sesame2SettingViewController(nibName: nil, bundle: nil)
        sesame2SettingViewController.sesame2 = sesame2
        sesame2SettingViewController.dismissHandler = dismissHandler
        sesame2SettingViewController.hidesBottomBarWhenPushed = true
        return sesame2SettingViewController
    }
}
