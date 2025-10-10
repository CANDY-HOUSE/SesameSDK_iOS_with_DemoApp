//
//  BikeLock2SettingViewController.swift
//  SesameUI
//
//  Created by JOi Chao on 2023/5/31.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import AWSMobileClientXCF
//import iOSDFULibrary
import NordicDFU
import CoreBluetooth
import IntentsUI

struct Bot2Event: PickerItemDiscriptor {
    var name: [UInt8]
    var displayName: String {
        return String(data: Data(name), encoding: .utf8)!
    }
    var selectHandler: ((PickerItemDiscriptor) -> Void)?
}

class Bot2SettingViewController: CHBaseViewController, CHDeviceStatusDelegate, DeviceControllerHolder{
    var device: SesameSDK.CHDevice!
    var bikeLock2: CHSesameBot2! {
        didSet {
            self.device = bikeLock2
        }
    }
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var statusView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var siriButton: CHUISettingButtonView?
    var scriptView: CHUIExpandableArrowSettingView!
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var isReset: Bool = false
    var pickerProxy: PickerProxy<Bot2Event>!
    
    // MARK: - Values for UI
    var versionStr: String? { //設備本身的韌體版號
        didSet {
            executeOnMainThread {
                self.dfuView.value = self.versionStr ?? ""
            }
        }
    }
    
    // MARK: - Callback(?
    var dismissHandler: ((_ isReset: Bool)->Void)?
    
    // MARK: - Life cycle
    deinit {
        self.deviceMemberWebView?.cleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        L.d("[bk2][settin VC] viewDidLoad <=")
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        if bikeLock2.keyLevel != KeyLevel.guest.rawValue {
            refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
            refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        arrangeSubviews()
//                DFUCenter.shared.confirmDFUDeletegate(self, forDevice: bikeLock2)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // L.d("[UI][bk2][viewWillAppear]")
        bikeLock2.delegate = self
        if bikeLock2.deviceStatus == .receivedBle() {
            bikeLock2.connect() { _ in }
        }
        getVersionTag()
        fetchActionModes()
        showStatusViewIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            DFUCenter.shared.removeDFUDelegateForDevice(bikeLock2)
            dismissHandler?(isReset)
        }
    }
    
    @objc func reloadFriends() {
        reloadMembers()
        refreshControl.endRefreshing()
    }
    
    // MARK: Main UI
    func arrangeSubviews(){
        // MARK: top status(最上方狀態列)
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        
        // MARK: Group
        if AWSMobileClient.default().currentUserState == .signedIn, bikeLock2.keyLevel != KeyLevel.guest.rawValue {
            contentStackView.addArrangedSubview(deviceMemberWebView(device.deviceId.uuidString))
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        }
        
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            self.changeName()
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = bikeLock2.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: 分享鑰匙
        if bikeLock2.keyLevel == KeyLevel.owner.rawValue || bikeLock2.keyLevel == KeyLevel.manager.rawValue {
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
        modelView.value = bikeLock2.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Permission (角色&權限)
        let permissionView = CHUIViewGenerator.plain()
        permissionView.title = "co.candyhouse.sesame2.Permission".localized
        permissionView.value = KeyLevel(rawValue: bikeLock2.keyLevel)!.description()
        contentStackView.addArrangedSubview(permissionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: 动作脚本
        scriptView = CHUIViewGenerator.arrowExpandable(){ [unowned self] sender,_ in
            guard ((sender as? UITapGestureRecognizer) != nil) else { return }
            self.navigateToSesameBot2VC(self.bikeLock2)
        }
        scriptView.title = "co.candyhouse.sesame2.Scripts".localized
        scriptView.fold()
        contentStackView.addArrangedSubview(scriptView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: SiriButton (Bikes只顯示unlock)
        if #available(iOS 12.0, *) {
            siriButton = CHUIViewGenerator.button() { [weak self] sender,_ in
                guard let self = self else { return }
                let intent = ToggleSesameIntent()
                intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                intent.name = self.bikeLock2.deviceName
                if let shortcut = INShortcut(intent: intent) {
                    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                        executeOnMainThread {
                            if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                               let voiceShortcutId = self.bikeLock2.getVoiceToggleId(),
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
            siriButton!.title = "co.candyhouse.sesame2.voiceShortcut".localized
            contentStackView.addArrangedSubview(siriButton!)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: DFU View
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized,
                                              style: .default) { _ in
                self.dfuSesame(self.bikeLock2)
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
        contentStackView.addArrangedSubview(dfuView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = bikeLock2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmDropKey(sender as! UIView) {
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?(true)
            }
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)

        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.holdKeyDesc".localized, arguments: [modelView.value, modelView.value, modelView.value])
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
        // MARK: Reset Sesame (for DEBUG)
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmResetKey(sender as! UIView) {
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif
    }

    // ---↓Functions↓---
    // MARK: getVersionTag (ssmOS version UI)
    private func getVersionTag() {
        bikeLock2.getVersionTag { result in
            switch result {
            case .success(let status):
//                L.d("[bk2][getVersionTag][.success] =>",status)
                let fileName = DFUHelper.getDfuFileName(self.bikeLock2!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
//                L.d("[bk2]getVersionTag",status.data,latestVersion,isnewest)
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(let error):
                L.d("[bk2][getVersionTag]",error.errorDescription())
            }
        }
    }
    // MARK: Handle Scripts
    private func updateScriptView(index: Int, event: PickerItemDiscriptor) {
        // UI 硬编码，未来作同步？
        UserDefaults.standard.setValue(index, forKey: device.deviceId.uuidString)
        self.scriptView.pickerView.selectRow(index, inComponent: 0, animated: false)
        self.scriptView.value = event.displayName
        self.scriptView.fold()
    }

    private func setupPickerWithEvents(_ events: [Bot2Event], currentIndex: Int) {
        self.pickerProxy = PickerProxy(items: events)
        self.scriptView.pickerView.dataSource = self.pickerProxy
        self.scriptView.pickerView.delegate = self.pickerProxy
        self.scriptView.pickerView.reloadAllComponents()
        self.scriptView.pickerView.selectRow(currentIndex, inComponent: 0, animated: false)
        self.scriptView.value = events[currentIndex].displayName
    }
    
    func fetchActionModes() {
        bikeLock2.getScriptNameList { [weak self] getResult in
            guard let self = self else { return }
            executeOnMainThread { [self] in
                if case let .success(bot2Status) = getResult {
                    let intValue: Int = UserDefaults.standard.integer(forKey: self.device.deviceId.uuidString)
                    bot2Status.data.curIdx = UInt8(intValue)
                    // 设置value
                    let events = bot2Status.data.events.enumerated().map { index, event -> Bot2Event in
                        return Bot2Event(name: event.name) { [weak self] e in
                            self?.bikeLock2.selectScript(index: UInt8(index)) { [weak self] res in
                                guard let self = self else { return }
                                executeOnMainThread {
                                    if case .success(_) = res {
                                        self.updateScriptView(index: index, event: e)
                                    } else if case let .failure(err) = res {
                                        self.view.makeToast(err.errorDescription())
                                    }
                                }
                            }
                        }
                    }
                    self.setupPickerWithEvents(events, currentIndex: Int(bot2Status.data.curIdx))
                }
            }
        }
    }
    
    // MARK: Change Name
    func changeName() {
        ChangeValueDialog.show(bikeLock2.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
            self.bikeLock2.setDeviceName(name)
            self.changeNameView.value = name
            if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                listViewController.reloadTableView()
            }

            if AWSMobileClient.default().currentUserState == .signedIn {
                var userKey = CHUserKey.fromCHDevice(self.bikeLock2)
                CHUserAPIManager.shared.getSubId { subId in
                    if let subId = subId {
                        userKey.subUUID = subId
                        CHUserAPIManager.shared.putCHUserKey(userKey) { _ in}
                    }
                }
            }
            WatchKitFileTransfer.shared.transferKeysToWatch()
        }
    }
    
    // MARK: presentQRCodeSharingView (Share QR codes)
    func presentQRCodeSharingView(sender: UIButton) {
        modalSheetToQRControlByRoleLevel(device: self.bikeLock2, sender: sender) { isComplete in
            if isComplete {
                self.reloadMembers()
            }
        }
    }
    
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            statusView.isHidden = false
        } else if bikeLock2.deviceStatus.loginStatus == .unlogined {
            statusView.title = bikeLock2.localizedDescription()
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }
        return !statusView.isHidden
    }
    
    // MARK: OTA(這是什麼縮寫???
    func dfuSesame(_ sesame: CHDevice) {
        DFUCenter.shared.dfuDevice(sesame, delegate: self)
        self.versionStr = nil
    }
}

extension Bot2SettingViewController {
    static func instanceWithBikeBot2(_ bot2: CHSesameBot2, dismissHandler: ((Bool)->Void)? = nil) -> Bot2SettingViewController {
        let sesame5SettingViewController = Bot2SettingViewController(nibName: nil, bundle: nil)
        sesame5SettingViewController.bikeLock2 = bot2
        sesame5SettingViewController.dismissHandler = dismissHandler
        sesame5SettingViewController.hidesBottomBarWhenPushed = true
        return sesame5SettingViewController
    }
}

extension Bot2SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
        if device.deviceId == bikeLock2.deviceId,
           status == .receivedBle() {
            device.connect() { _ in }
        } else if status.loginStatus == .logined {
            if versionStr == nil {
                getVersionTag()
                fetchActionModes()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
}

// MARK: - DFUHelperDelegate
extension Bot2SettingViewController: DFUHelperDelegate {
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

// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension Bot2SettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is ToggleSesameIntent {
            bikeLock2.setVoiceToggle(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension Bot2SettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                self.bikeLock2.removeVoiceToggle()
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
