//
//  Sesame2SettingViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF
//import iOSDFULibrary
import NordicDFU
import CoreBluetooth
import IntentsUI

class Sesame2SettingViewController: CHBaseViewController, DeviceControllerHolder {
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!

    var sesame2: CHSesame2! {
        didSet {
            device = sesame2
        }
    }
    let scrollView = UIScrollView(frame: .zero)
    var statusView: CHUIPlainSettingView!
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var angleSettingView: CHUIArrowSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var autoLockView: CHUITogglePickerSettingView!
    var autoUnLockView: CHUIArrowSettingView!
    var notificationToggleView: CHUIToggleSettingView?
    var deviceMembersView: KeyCollectionViewController!
    var friendListHeight: NSLayoutConstraint!
    var voiceShortcutButton: CHUISettingButtonView?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var versionExclamationContainerView: UIView!
    
    // MARK: - Flags
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
                self.secondPickerSelectedRow = self.secondSettingValue.firstIndex(of: self.autoLock!) ?? 0
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
        
        if sesame2.keyLevel != KeyLevel.guest.rawValue {
            refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
            refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill

        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        if let deviceToken = UserDefaults.standard.string(forKey: "devicePushToken"), sesame2.keyLevel != KeyLevel.guest.rawValue {
            sesame2.isNotificationEnabled(token: deviceToken, name: "Sesame2") { result in
                if case let .success(isEnabled) = result {
                    executeOnMainThread {
                        self.notificationToggleView?.switchView.isOn = isEnabled.data
                    }
                }
            }
        }
        arrangeSubviews()
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: sesame2)
    }
    
    @objc func reloadFriends() {
        deviceMembersView?.getMembers()
        refreshControl.endRefreshing()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        // MARK: top status
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        // MARK: Group
        if AWSMobileClient.default().currentUserState == .signedIn, sesame2.keyLevel != KeyLevel.guest.rawValue {
            deviceMembersView = KeyCollectionViewController.instanceWithDevice(sesame2)
            addChild(deviceMembersView)
            let collectionViewContainer = UIView(frame: .zero)
            friendListHeight = collectionViewContainer.autoLayoutHeight(90)
            collectionViewContainer.addSubview(deviceMembersView.view)
            deviceMembersView.view.autoPinTop()
            deviceMembersView.view.autoPinBottom()
            deviceMembersView.view.autoPinLeading()
            deviceMembersView.view.autoPinTrailing()
            contentStackView.addArrangedSubview(collectionViewContainer)
            
            deviceMembersView.didMove(toParent: self)
            deviceMembersView.delegate = self
            
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        }
        
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            self.changeName()
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = sesame2.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        if sesame2.keyLevel == KeyLevel.owner.rawValue || sesame2.keyLevel == KeyLevel.manager.rawValue {
            let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
                self.presentQRCodeSharingView(sender: sender as! UIButton)
            }
            shareKeyView.title = "co.candyhouse.sesame2.ShareTheKey".localized
            contentStackView.addArrangedSubview(shareKeyView)
        }
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))


        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = sesame2.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        // MARK: Permission
        let permissionView = CHUIViewGenerator.plain()
        permissionView.title = "co.candyhouse.sesame2.Permission".localized
        permissionView.value = KeyLevel(rawValue: sesame2.keyLevel)!.description()
        contentStackView.addArrangedSubview(permissionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Angle setting
        if sesame2.keyLevel == KeyLevel.owner.rawValue || sesame2.keyLevel == KeyLevel.manager.rawValue {
            angleSettingView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                navigationController?.pushViewController(LockAngleSettingViewController.instanceWithSesame2(sesame2),animated: true)
            }
            angleSettingView.title = "co.candyhouse.sesame2.ConfigureAngles".localized
            contentStackView.addArrangedSubview(angleSettingView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: Enable Notification
        if sesame2.keyLevel != KeyLevel.guest.rawValue {
            notificationToggleView = CHUIViewGenerator.toggle { [unowned self] sender,_ in
                if let toggle = sender as? UISwitch {
                    self.enableNotificationToggled(sender: toggle)
                }
            }
            notificationToggleView!.title = "co.candyhouse.sesame2.enableNotification".localized
            contentStackView.addArrangedSubview(notificationToggleView!)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: AutoLock
        if sesame2.keyLevel == KeyLevel.owner.rawValue || sesame2.keyLevel == KeyLevel.manager.rawValue {
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
        }
        
//        // MARK: AutoUnlock
//        autoUnLockView = CHUIViewGenerator.arrow() { [unowned self] sender,_ in
//            self.navigationController?.pushViewController(GPSMapViewController.instanceWithSesame2(sesame2), animated: true)
//        }
//        autoUnLockView.title = "co.candyhouse.sesame2.AutoUnlock".localized
//        autoUnLockView.value = self.sesame2.autoUnlockStatus() == true ? "co.candyhouse.sesame2.on".localized : "co.candyhouse.sesame2.off".localized
//        contentStackView.addArrangedSubview(autoUnLockView)
//        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: SiriButton
        if #available(iOS 12.0, *) {
            voiceShortcutButton = CHUIViewGenerator.button() { [unowned self] sender,_ in

                let chooseVoiceShortcutViewController = UIAlertController(title: nil, message: "co.candyhouse.sesame2.chooseVoiceShortcut".localized, preferredStyle: .actionSheet)
                
                let toggleShortcut = UIAlertAction(title: "co.candyhouse.sesame2.toggle".localized, style: .default) { _ in
                    let intent = ToggleSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame2.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame2.getVoiceToggleId(),
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
                
                let lockShortcut = UIAlertAction(title: "co.candyhouse.sesame2.lock".localized, style: .default) { _ in
                    let intent = LockSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame2.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame2.getVoiceLockId(),
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
                
                let unlockShortcut = UIAlertAction(title: "co.candyhouse.sesame2.unlock".localized, style: .default) { _ in
                    let intent = UnlockSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame2.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame2.getVoiceUnlockId(),
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
                chooseVoiceShortcutViewController.addAction(toggleShortcut)
                chooseVoiceShortcutViewController.addAction(lockShortcut)
                chooseVoiceShortcutViewController.addAction(unlockShortcut)
                chooseVoiceShortcutViewController.addAction(.init(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil))
                chooseVoiceShortcutViewController.popoverPresentationController?.sourceView = voiceShortcutButton
                present(chooseVoiceShortcutViewController, animated: true, completion: nil)
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
        uuidView.value = sesame2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmDropKey(sender as! UIView) {
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop Key Desc
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized])
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
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
        #endif

        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))


        // MARK: AutoUnlock
        autoUnLockView = CHUIViewGenerator.arrow() { [unowned self] sender,_ in
            self.navigationController?.pushViewController(GPSMapViewController.instanceWithSesame2(sesame2), animated: true)
        }
        autoUnLockView.title = "co.candyhouse.sesame2.AutoUnlock".localized
        autoUnLockView.value = self.sesame2.autoUnlockStatus() == true ? "co.candyhouse.sesame2.on".localized : "co.candyhouse.sesame2.off".localized
        contentStackView.addArrangedSubview(autoUnLockView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
//        // start MARK: AutoUnlock
//        autoUnLockView = CHUIViewGenerator.arrow() { [unowned self] sender,_ in
//            self.navigationController?.pushViewController(GPSMapViewController.instanceWithSesame2(sesame5), animated: true)
//        }
//        autoUnLockView.title = "co.candyhouse.sesame2.AutoUnlock".localized
//
//        contentStackView.addArrangedSubview(autoUnLockView)
//        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
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
    
    override func didBecomeActive() {
        viewWillAppear(true)
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
        autoLockView?.switchView.isOn = !isHiddenAutoLockDisplay
        autoLockView?.switchView.isEnabled = sesame2.deviceStatus.loginStatus == .logined
        autoLockView?.button.isEnabled = sesame2.deviceStatus.loginStatus == .logined
        autoLockView?.value = isHiddenAutoLockDisplay ? "" : autoLockValueLabelText
        autoLockView?.pickerView.selectRow(secondPickerSelectedRow, inComponent: 0, animated: false)
        autoUnLockView.value = self.sesame2.autoUnlockStatus() == true ? "co.candyhouse.sesame2.on".localized : "co.candyhouse.sesame2.off".localized
        dfuView.value = version ?? ""
        changeNameView.value = sesame2.deviceName
        showStatusViewIfNeeded()
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
                let fileName = DFUHelper.getDfuFileName(self.sesame2!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
//                L.d("getVersionTag",status.data,latestVersion,isnewest)
                self.version = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(let error):
                L.d(error.errorDescription())
            }
        }
    }
    
    // MARK: changeName
    func changeName() {
        let placeholder = sesame2.deviceName
        
        ChangeValueDialog.show(placeholder, title: "co.candyhouse.sesame2.EditName".localized) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame2.EditName".localized)
                return
            }
            self.sesame2.setDeviceName(name)
            
            if AWSMobileClient.default().currentUserState == .signedIn {
                var userKey = CHUserKey.fromCHDevice(self.sesame2)
                CHUserAPIManager.shared.getSubId { subId in
                    if let subId = subId {
                        userKey.subUUID = subId
                        CHUserAPIManager.shared.putCHUserKey(userKey) { _ in
                            
                        }
                    }
                }
            }
            
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
    
    // MARK: enableNotificationToggle
    func enableNotificationToggled(sender: UISwitch) {
        ViewHelper.showLoadingInView(view: self.notificationToggleView)
        if let deviceToken = UserDefaults.standard.string(forKey: "devicePushToken") {
            if sender.isOn == true {
                CHUserAPIManager.shared.getSubId {  [weak self] subId in
                    guard let self = self else { return }
                    sesame2.enableNotification(token: deviceToken, name: "Sesame2", subUUID: subId) { result in
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.notificationToggleView)
                        }
                    }
                }
            } else {
                sesame2.disableNotification(token: deviceToken, name: "Sesame2") { result in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.notificationToggleView)
                    }
                }
            }
        }
    }

    
    // MARK: presentQRCodeSharingView
    func presentQRCodeSharingView(sender: UIButton) {
        let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.ShareFriend".localized, preferredStyle: .actionSheet)
        if sesame2.keyLevel == 0 {
            let ownerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.ownerKey".localized, style: .default) { _ in
                executeOnMainThread {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesame2, keyLevel: KeyLevel.owner.rawValue) {
                        self.deviceMembersView?.getMembers()
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(ownerKeyAction)
        }
        
        if (sesame2.keyLevel == 0 || sesame2.keyLevel == 1) {
            let managerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.managerKey".localized, style: .default) { _ in
                executeOnMainThread {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesame2, keyLevel: KeyLevel.manager.rawValue)  {
                        self.deviceMembersView?.getMembers()
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(managerKeyAction)
        }
        

        let memberKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.memberKey".localized, style: .default) { _ in
            executeOnMainThread {
                if self.sesame2.keyLevel == KeyLevel.guest.rawValue {
                    let qrCode = URL.qrCodeURLFromDevice(self.sesame2, deviceName: self.sesame2.deviceName, keyLevel: KeyLevel.guest.rawValue)
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesame2, qrCode: qrCode!)
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                } else {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.sesame2, keyLevel: KeyLevel.guest.rawValue) {
                        self.deviceMembersView?.getMembers()
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
        }
        alertController.addAction(memberKeyAction)
        
        
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: OTA
    func dfuSesame2(_ sesame2: CHSesame2) {
        DFUCenter.shared.dfuDevice(sesame2, delegate: self)
        self.version = nil
    }
    
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            statusView.isHidden = false
        } else if sesame2.deviceStatus.loginStatus == .unlogined {
            statusView.title = sesame2.localizedDescription()
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }
        return !statusView.isHidden
    }

}

// MARK: - CHSesame2Delegate
extension Sesame2SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
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
            executeOnMainThread {
                self.refreshUI()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
}

// MARK: - TableView data source and delegate
extension Sesame2SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    // MARK: UIPickerViewDataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        secondSettingValue.count
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        
        if pickerLabel == nil{
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16)
            pickerLabel?.textAlignment = .center
            pickerLabel?.text = formatedTimeFromSec(secondSettingValue[row])
        }
        return pickerLabel!
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        autoLockView.fold()
        secondPickerDidSelectRow(row)
    }
    

    // MARK: secondPickerDidSelectRow
    func secondPickerDidSelectRow(_ row: Int) {
        ViewHelper.showLoadingInView(view: self.autoLockView)
        sesame2.enableAutolock(delay: secondSettingValue[row]) { result  in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.autoLockView)
                switch result {
                case .success(let delay):
                    self.isHiddenAutoLockDisplay = delay.data > 0 ? false : true
                    self.autoLockView.switchView.isOn = delay.data > 0
                    self.autoLockValueLabelText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [self.formatedTimeFromSec(self.secondSettingValue[row])])
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

extension Sesame2SettingViewController: KeyCollectionViewControllerDelegate {
    func collectionViewHeightDidChanged(_ height: CGFloat) {
        friendListHeight.constant = height
    }
    
    func noPermission() {
        executeOnMainThread {
            self.deviceMembersView.view.isHidden = true
            self.friendListHeight.constant = 0
        }
    }
}

// MARK: - INUIAddVoiceShortcutButtonDelegate
extension Sesame2SettingViewController: INUIAddVoiceShortcutButtonDelegate {
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
extension Sesame2SettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is ToggleSesameIntent {
            sesame2.setVoiceToggle(voiceShortcut!.identifier)
        } else if voiceShortcut?.shortcut.intent is LockSesameIntent {
            sesame2.setVoiceLock(voiceShortcut!.identifier)
        } else if voiceShortcut?.shortcut.intent is UnlockSesameIntent {
            sesame2.setVoiceUnlock(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension Sesame2SettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                self.sesame2.removeVoiceToggle()
            } else if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is LockSesameIntent }).first {
                self.sesame2.removeVoiceLock()
            } else if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is UnlockSesameIntent }).first {
                self.sesame2.removeVoiceUnlock()
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
extension Sesame2SettingViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2, dismissHandler: ((Bool)->Void)? = nil) -> Sesame2SettingViewController {
        let sesame2SettingViewController = Sesame2SettingViewController(nibName: nil, bundle: nil)
        sesame2SettingViewController.sesame2 = sesame2
        sesame2SettingViewController.dismissHandler = dismissHandler
        sesame2SettingViewController.hidesBottomBarWhenPushed = true
        return sesame2SettingViewController
    }
}
