//
//  BikeLockSettingViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF
import SesameSDK
//import iOSDFULibrary
import NordicDFU
import IntentsUI

class BikeLockSettingViewController: CHBaseViewController, DeviceControllerHolder {
    
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!

    // MARK: - Data model
    var bikeLock: CHSesameBike! {
        didSet {
            device = bikeLock
        }
    }
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var deviceMembersView: KeyCollectionViewController!
    var statusView: CHUIPlainSettingView!
    var voiceShortcutButton: CHUISettingButtonView?
    var refreshControl: UIRefreshControl = UIRefreshControl()
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
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: bikeLock)
        showStatusViewIfNeeded()
        
        if bikeLock.keyLevel != KeyLevel.guest.rawValue {
            refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
            refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }
    }
    
    @objc func reloadFriends() {
        deviceMembersView?.getMembers()
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
        if AWSMobileClient.default().currentUserState == .signedIn, bikeLock.keyLevel != KeyLevel.guest.rawValue {
            deviceMembersView = KeyCollectionViewController.instanceWithDevice(bikeLock)
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
        changeNameView.value = bikeLock.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        if bikeLock.keyLevel == KeyLevel.owner.rawValue || bikeLock.keyLevel == KeyLevel.manager.rawValue {
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
        modelView.value = bikeLock.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        // MARK: Permission
        let permissionView = CHUIViewGenerator.plain()
        permissionView.title = "co.candyhouse.sesame2.Permission".localized
        permissionView.value = KeyLevel(rawValue: bikeLock.keyLevel)!.description()
        contentStackView.addArrangedSubview(permissionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: SiriButton
        if #available(iOS 12.0, *) {
            voiceShortcutButton = CHUIViewGenerator.button() { [unowned self] sender,_ in
                let intent = UnlockSesameIntent()
                intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                intent.name = self.bikeLock.deviceName
                if let shortcut = INShortcut(intent: intent) {
                    INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                        executeOnMainThread {
                            if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                               let voiceShortcutId = self.bikeLock.getVoiceToggleId(),
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
                self.dfuSesame2(self.bikeLock)
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
        exclamation.contentMode = .scaleAspectFit
        versionExclamationContainerView.addSubview(exclamation)
        dfuView.appendViewToTitle(versionExclamationContainerView)
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
        uuidView.value = bikeLock.deviceId.uuidString
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
        
        // MARK: Drop Key Desc
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.holdKeyDesc".localized, arguments: ["co.candyhouse.sesame2.BikeLock".localized, "co.candyhouse.sesame2.BikeLock".localized, "co.candyhouse.sesame2.BikeLock".localized])
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
        bikeLock.delegate = self
        if bikeLock.deviceStatus == .receivedBle() {
            bikeLock.connect() { _ in }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            DFUCenter.shared.removeDFUDelegateForDevice(bikeLock)
            dismissHandler?()
        }
    }

    // MARK: RefreshUI
    func refreshUI() {
        dfuView.value = versionStr ?? ""
        changeNameView.value = bikeLock.deviceName
    }

    // MARK: getVersionTag
    private func getVersionTag() {
        bikeLock.getVersionTag { result in
            switch result {
            case .success(let status):
                let fileName = DFUHelper.getDfuFileName(self.bikeLock!).split(separator: "_")
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
    
    // MARK: changeName
    func changeName() {
        ChangeValueDialog.show(bikeLock.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame2.EditName".localized)
                return
            }
            self.bikeLock.setDeviceName(name)
            
            if AWSMobileClient.default().currentUserState == .signedIn {
                var userKey = CHUserKey.fromCHDevice(self.bikeLock)
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
    
    // MARK: presentQRCodeSharingView
    func presentQRCodeSharingView(sender: UIButton) {
        let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.ShareFriend".localized, preferredStyle: .actionSheet)
        if bikeLock.keyLevel == 0 {
            let ownerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.ownerKey".localized, style: .default) { _ in
                DispatchQueue.main.async {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.bikeLock, keyLevel: KeyLevel.owner.rawValue) {
                        self.deviceMembersView?.getMembers()
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(ownerKeyAction)
        }

        if (bikeLock.keyLevel == 0 || bikeLock.keyLevel == 1) {
            let managerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.managerKey".localized, style: .default) { _ in
                DispatchQueue.main.async {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.bikeLock, keyLevel: KeyLevel.manager.rawValue)
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(managerKeyAction)
        }
        

        let memberKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.memberKey".localized, style: .default) { _ in
            DispatchQueue.main.async {
                if self.bikeLock.keyLevel == KeyLevel.guest.rawValue {
                    let qrCode = URL.qrCodeURLFromDevice(self.bikeLock, deviceName: self.bikeLock.deviceName, keyLevel: KeyLevel.guest.rawValue)
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.bikeLock, qrCode: qrCode!)
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                } else {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.bikeLock, keyLevel: KeyLevel.guest.rawValue) {
                        self.deviceMembersView?.getGuestKeys()
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
    func dfuSesame2(_ bikeLock: CHSesameBike) {
        DFUCenter.shared.dfuDevice(bikeLock, delegate: self)
        self.versionStr = nil
    }
    
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if bikeLock.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = bikeLock.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
        return !statusView.isHidden
    }
}

// MARK: - CHSesame2Delegate
extension BikeLockSettingViewController: CHSesameBikeDelegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
        
        if device.deviceId == bikeLock.deviceId,
            status == .receivedBle() {
            device.connect() { _ in }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
}

// MARK: - DFUHelperDelegate
extension BikeLockSettingViewController: DFUHelperDelegate {
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

extension BikeLockSettingViewController: KeyCollectionViewControllerDelegate {
    func collectionViewHeightDidChanged(_ height: CGFloat) {
        friendListHeight.constant = height
    }
    
    func noPermission() {
        executeOnMainThread {
            self.friendListHeight.constant = 0
        }
    }
}

// MARK: - INUIAddVoiceShortcutButtonDelegate
extension BikeLockSettingViewController: INUIAddVoiceShortcutButtonDelegate {
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
extension BikeLockSettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is UnlockSesameIntent {
            bikeLock.setVoiceToggle(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension BikeLockSettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                self.bikeLock.removeVoiceToggle()
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
extension BikeLockSettingViewController {
    static func instanceWithBikeLock(_ bikeLock: CHSesameBike, dismissHandler: (()->Void)? = nil) -> BikeLockSettingViewController {
        let bikeLockSettingViewController = BikeLockSettingViewController(nibName: nil, bundle: nil)
        bikeLockSettingViewController.hidesBottomBarWhenPushed = true
        bikeLockSettingViewController.bikeLock = bikeLock
        bikeLockSettingViewController.dismissHandler = dismissHandler
        return bikeLockSettingViewController
    }
}
