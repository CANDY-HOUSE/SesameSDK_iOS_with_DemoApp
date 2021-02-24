//
//  SesameBotSettingViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import iOSDFULibrary
import CoreBluetooth

class SesameBotSettingViewController: CHBaseViewController {
    
    // MARK: - Data model
    var sesameBot: CHSesameBot!
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var statusView: CHUIPlainSettingView!
    var sesameBotModeView: CHUISettingButtonView!
    
    var dfuView: CHUIPlainSettingView!
    
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
    var advInterval = ""
    var txPower = ""
    var autoLockValueLabelText = ""
    var secondPickerSelectedRow: Int = 0
    var advIntervalPickerSelectedRow: Int = 0
    var txPowerPickerSelectedRow: Int = 0
    
    // MARK: - Callback
    var dismissHandler: (()->Void)?
    
    var friendListHeight: NSLayoutConstraint!
    
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
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: sesameBot)
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
        changeNameView.value = sesameBot.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
            self.presentQRCodeSharingView(sender: sender as! UIButton)
        }
        shareKeyView.title = "co.candyhouse.sesame2.ShareTheKey".localized
        contentStackView.addArrangedSubview(shareKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Operation Type
        sesameBotModeView = CHUIViewGenerator.button { [unowned self] button,_ in
            self.changeMode()
        }
        sesameBotModeView.title = "co.candyhouse.sesame2.sesameBotMode".localized
        sesameBotModeView.value = SesameBotClickMode.modeForSesameBot(sesameBot)?.desc() ?? ""
        contentStackView.addArrangedSubview(sesameBotModeView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)

            let confirmAction = UIAlertAction(title: DFUHelper.sesameBotApplicationDfuFileName()!,
                                              style: .default) { _ in
                self.dfuSesame2(self.sesameBot)
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
        uuidView.value = sesameBot.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)

        // MARK: Drop key
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.trashKey(sender: sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop Key Desc
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.SesameBot".localized, "co.candyhouse.sesame2.SesameBot".localized, "co.candyhouse.sesame2.SesameBot".localized])
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
            self.presentResetAlert(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getVersionTag()
        sesameBot.delegate = self
        if sesameBot.deviceStatus == .receivedBle() {
            sesameBot.connect() { _ in }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            DFUCenter.shared.removeDFUDelegateForDevice(sesameBot)
            dismissHandler?()
        }
    }

    func refreshUI() {
        dfuView.value = version ?? ""
        changeNameView.value = sesameBot.deviceName
        sesameBotModeView.value = sesameBot.sesameBotMode?.desc() ?? ""
    }
    
    func changeMode() {
        
        let nextMode = sesameBot.sesameBotMode?.next()
        if nextMode == .normal {
            if var mechSetting = sesameBot.mechSetting {
                mechSetting.userPrefDir = .normal
                mechSetting.lockSecConfig.clickLockSeconds = UInt8(10.0)
                mechSetting.lockSecConfig.clickHoldSeconds = UInt8(10.0)
                mechSetting.lockSecConfig.clickUnlockSeconds = UInt8(8.0)
                sesameBot.updateSetting(setting: mechSetting) { _ in
                    executeOnMainThread {
                        self.refreshUI()
                    }
                }
            }
        }
        else if nextMode == .circle {
            if var mechSetting = sesameBot.mechSetting {
                mechSetting.userPrefDir = .normal
                mechSetting.lockSecConfig.clickLockSeconds = UInt8(20.0)
                mechSetting.lockSecConfig.clickHoldSeconds = UInt8(0.0)
                mechSetting.lockSecConfig.clickUnlockSeconds = UInt8(0.0)
                sesameBot.updateSetting(setting: mechSetting) { _ in
                    executeOnMainThread {
                        self.refreshUI()
                    }
                }
            }
        } else if nextMode == .longPress {
            if var mechSetting = sesameBot.mechSetting {
                mechSetting.userPrefDir = .reversed
                mechSetting.lockSecConfig.clickLockSeconds = UInt8(10.0)
                mechSetting.lockSecConfig.clickHoldSeconds = UInt8(20.0)
                mechSetting.lockSecConfig.clickUnlockSeconds = UInt8(15.0)
                sesameBot.updateSetting(setting: mechSetting) { _ in
                    executeOnMainThread {
                        self.refreshUI()
                    }
                }
            }
//            let setting = SesameBotMechSettings(userPrefDir: .reversed,
//                                  clickSecs: .init(clickLockSecond: 1.0, clickHoldSecond: 2.0, clickUnlockSecond: 1.5),
//                                  buttonMode: .click)
//
//            sesameBot.updateSetting(setting: setting) { _ in
//                executeOnMainThread {
//                    self.refreshUI()
//                }
//            }
        }
    }
    
    // MARK: getVersionTag
    private func getVersionTag() {
        sesameBot.getVersionTag { result in
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
        let placeholder = sesameBot.deviceName
        ChangeValueDialog.show(placeholder, title: "co.candyhouse.sesame2.EditSesameName".localized) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame2.EditSesameName".localized)
                return
            }
            self.sesameBot.setDeviceName(name)
            
            WatchKitFileTransfer.shared.transferKeysToWatch()
            self.refreshUI()
            
            if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                listViewController.reloadTableView()
            }
        }
    }
    
    // MARK: presentQRCodeSharingView
    func presentQRCodeSharingView(sender: UIButton) {
        executeOnMainThread {
            let deviceKey = self.sesameBot.getKey()
            let qrCode = URL.qrCodeURLFromDeviceKey(deviceKey!, deviceName: self.sesameBot.deviceName)
            let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesameBot, qrCode: qrCode!)
            self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
        }
    }
    
    // MARK: OTA
    func dfuSesame2(_ sesameBot: CHSesameBot) {
        DFUCenter.shared.dfuDevice(sesameBot, delegate: self)
        self.version = nil
    }
    
    // MARK: trashKey
    func trashKey(sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.TrashTheKey".localized,
                                            style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            
            self.sesameBot.dropUserKey { result in
                if case let .failure(error) = result {
                    L.d(error.errorDescription())
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                    }
                } else {
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.navigationController?.popToRootViewController(animated: false)
                        self.dismissHandler?()
                    }
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
    
    func presentResetAlert(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                      style: .destructive) { _ in
            self.resetSesameBotDevice()
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
    public func resetSesameBotDevice() {
        ViewHelper.showLoadingInView(view: view)
        sesameBot?.resetUserKey({ result in
            if case let .failure(error) = result {
                L.d(error.errorDescription())
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                }
            } else {
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.navigationController?.popToRootViewController(animated: false)
                    self.dismissHandler?()
                }
            }
        })
    }
    
    func showStatusViewIfNeeded() {
        if CHBleManager.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if sesameBot.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = sesameBot.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
    }
}

// MARK: - CHSesame2Delegate
extension SesameBotSettingViewController: CHSesameBotDelegate {
    public func onBleDeviceStatusChanged(device: SesameLock,
                                         status: CHSesame2Status,
                                         shadowStatus: CHSesame2ShadowStatus?) {
        
        if device.deviceId == sesameBot.deviceId,
            status == .receivedBle() {
            device.connect() { _ in }
        } else if status.loginStatus == .logined {
            if version == nil {
                getVersionTag()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
    
    func onMechStatusChanged(device: CHSesameBot, status: SesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
}

// MARK: - DFUHelperDelegate
extension SesameBotSettingViewController: DFUHelperDelegate {
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
extension SesameBotSettingViewController {
    static func instanceWithSwitch(_ sesameBot: CHSesameBot, dismissHandler: (()->Void)? = nil) -> SesameBotSettingViewController {
        let sesameBotSettingViewController = SesameBotSettingViewController(nibName: nil, bundle: nil)
        sesameBotSettingViewController.hidesBottomBarWhenPushed = true
        sesameBotSettingViewController.sesameBot = sesameBot
        sesameBotSettingViewController.dismissHandler = dismissHandler
        return sesameBotSettingViewController
    }
}
