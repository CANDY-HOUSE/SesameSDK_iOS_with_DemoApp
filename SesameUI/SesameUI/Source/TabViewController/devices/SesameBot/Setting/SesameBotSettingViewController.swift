//
//  SesameBotSettingViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF
import SesameSDK
//import iOSDFULibrary
import NordicDFU
import CoreBluetooth
import IntentsUI

class SesameBotSettingViewController: CHBaseViewController, DeviceControllerHolder {
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!
    
    // MARK: - Data model
    var sesameBot: CHSesameBot! {
        didSet {
            device = sesameBot
        }
    }
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var statusView: CHUIPlainSettingView!
    var sesameBotModeView: CHUISettingButtonView!
    var voiceShortcutButton: CHUISettingButtonView?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var dfuView: CHUIPlainSettingView!
    var versionExclamationContainerView: UIView!
    
    // MARK: - Values for UI
    var versionStr: String? {
        didSet {
            guard versionStr != nil else {
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
    
    // MARK: - Life cycle
    deinit {
        self.deviceMemberWebView?.cleanup()
    }
    
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
        
        if sesameBot.keyLevel != KeyLevel.guest.rawValue {
            refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
            refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }
    }
    
    @objc func reloadFriends() {
        reloadMembers()
        refreshControl.endRefreshing()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        
        // MARK: Group
        contentStackView.addArrangedSubview(deviceMemberWebView(device))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
     
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = sesameBot.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Operation Type
        sesameBotModeView = CHUIViewGenerator.button { [unowned self] button,_ in
            self.changeMode()
        }
        sesameBotModeView.title = "co.candyhouse.sesame2.sesameBotMode".localized
        sesameBotModeView.value = SesameBotClickMode.modeForSesameBot(sesameBot)?.desc() ?? ""
        contentStackView.addArrangedSubview(sesameBotModeView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: SiriButton
        if #available(iOS 12.0, *) {
            voiceShortcutButton = CHUIViewGenerator.button() { [unowned self] sender,_ in
                let intent = ToggleSesameIntent()
                intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                intent.name = self.sesameBot.deviceName
                if let shortcut = INShortcut(intent: intent) {
                    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                        executeOnMainThread {
                            if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                               let voiceShortcutId = self.sesameBot.getVoiceToggleId(),
                               voiceShortcutIds.contains(voiceShortcutId) {
                                let voiceShortcut = shortcuts!.filter({ $0.identifier == voiceShortcutId }).first!
                                let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                                viewController.modalPresentationStyle = .formSheet
                                viewController.delegate = self
                                self.present(viewController, animated: true, completion: nil)
                            } else {
                                let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                                viewController.modalPresentationStyle = .formSheet
                                viewController.delegate = self
                                self.present(viewController, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            voiceShortcutButton!.title = "co.candyhouse.sesame2.voiceShortcut".localized
            contentStackView.addArrangedSubview(voiceShortcutButton!)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)

            let confirmAction = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized,
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
        dfuView.value = versionStr ?? ""
        contentStackView.addArrangedSubview(dfuView)
        
        versionExclamationContainerView = UIView(frame: .zero)
        let exclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed))
        versionExclamationContainerView.addSubview(exclamation)
        dfuView.appendViewToTitle(versionExclamationContainerView)
        versionExclamationContainerView.autoLayoutWidth(20)
        versionExclamationContainerView.autoLayoutHeight(20)
        exclamation.autoLayoutWidth(20)
        exclamation.autoLayoutHeight(20)
        exclamation.autoPinCenterY()
        versionExclamationContainerView.isHidden = true
        
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
            self.prepareConfirmDropKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop Key Desc
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.holdKeyDesc".localized, arguments: ["co.candyhouse.sesame2.SesameBot".localized, "co.candyhouse.sesame2.SesameBot".localized, "co.candyhouse.sesame2.SesameBot".localized])
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        titleLabel.lineBreakMode = .byWordWrapping // 按單詞換行
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
            self.prepareConfirmResetKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
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
        dfuView.value = versionStr ?? ""
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
        }
    }
    
    // MARK: getVersionTag
    private func getVersionTag() {
        sesameBot.getVersionTag { result in
            switch result {
            case .success(let status):
                let fileName = DFUHelper.getDfuFileName(self.sesameBot!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(let error):
                L.d("[bk2][getVersionTag]",error.errorDescription())
            }
        }
    }
    
    // MARK: OTA
    func dfuSesame2(_ sesameBot: CHSesameBot) {
        DFUCenter.shared.dfuDevice(sesameBot, delegate: self)
        self.versionStr = nil
    }
    
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if sesameBot.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = sesameBot.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
        return !statusView.isHidden
    }
}

// MARK: - CHSesame2Delegate
extension SesameBotSettingViewController: CHSesameBotDelegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
        
        if device.deviceId == sesameBot.deviceId,
            status == .receivedBle() {
            device.connect() { _ in }
        } else if status.loginStatus == .logined {
            if versionStr == nil {
                getVersionTag()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
    
    func onMechStatus(device: CHDevice) {
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

// MARK: - INUIAddVoiceShortcutButtonDelegate
extension SesameBotSettingViewController: INUIAddVoiceShortcutButtonDelegate {
    @available(iOS 12.0, *)
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension SesameBotSettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is ToggleSesameIntent {
            sesameBot.setVoiceToggle(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension SesameBotSettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                self.sesameBot.removeVoiceToggle()
            }
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
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
