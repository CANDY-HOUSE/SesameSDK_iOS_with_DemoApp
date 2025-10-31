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

class BikeLock2SettingViewController: CHBaseViewController, CHDeviceStatusDelegate, DeviceControllerHolder {
    
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!
    
    var bikeLock2: CHSesameBike2! {
        didSet {
            device = bikeLock2
        }
    }
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var statusView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var siriButton: CHUISettingButtonView?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var isReset: Bool = false
    
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
        view.addSubview(scrollView)
        
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
        contentStackView.addArrangedSubview(deviceMemberWebView(device))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = bikeLock2.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: SiriButton (Bikes只顯示unlock)
        if #available(iOS 12.0, *) {
            siriButton = CHUIViewGenerator.button() { [unowned self] sender,_ in
                let chooseSiriViewController = UIAlertController(title: nil, message: "co.candyhouse.sesame2.chooseVoiceShortcut".localized, preferredStyle: .actionSheet)
        
            let unlockShortcut = UIAlertAction(title: "co.candyhouse.sesame2.unlock".localized, style: .default) { _ in
                let intent = UnlockSesameIntent()
                intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized //建議的Siri指令default
                intent.name = self.bikeLock2.deviceName

            //決定要編輯一個已經存在的siri捷徑，還是添加一個新的siri捷徑
            if let shortcutForSiri = INShortcut(intent: intent) {
                INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                    executeOnMainThread {
                        let siriID = self.bikeLock2.getVoiceUnlockId()
                        let existingShortcuts = shortcuts?.first(where: { $0.identifier == siriID })

                        if let existingShortcuts = existingShortcuts {
                            let vcEdit = INUIEditVoiceShortcutViewController(voiceShortcut: existingShortcuts)
                            vcEdit.modalPresentationStyle = .formSheet
                            vcEdit.delegate = self
                            self.present(vcEdit, animated: true, completion: nil)
                        } else {
                            let vcAdd = INUIAddVoiceShortcutViewController(shortcut: shortcutForSiri)
                            vcAdd.modalPresentationStyle = .formSheet
                            vcAdd.delegate = self
                            self.present(vcAdd, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
                chooseSiriViewController.addAction(unlockShortcut)
                chooseSiriViewController.addAction(.init(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil))
                chooseSiriViewController.popoverPresentationController?.sourceView = siriButton
                present(chooseSiriViewController, animated: true, completion: nil)
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
            }
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.holdKeyDesc".localized, arguments: ["co.candyhouse.sesame2.BikeLock2".localized, "co.candyhouse.sesame2.BikeLock2".localized, "co.candyhouse.sesame2.BikeLock2".localized])
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

extension BikeLock2SettingViewController {
    static func instanceWithBikeLock2(_ bikeLock2: CHSesameBike2, dismissHandler: ((Bool)->Void)? = nil) -> BikeLock2SettingViewController {
        let sesame5SettingViewController = BikeLock2SettingViewController(nibName: nil, bundle: nil)
        sesame5SettingViewController.bikeLock2 = bikeLock2
        sesame5SettingViewController.dismissHandler = dismissHandler
        sesame5SettingViewController.hidesBottomBarWhenPushed = true
        return sesame5SettingViewController
    }
}

extension BikeLock2SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
        if device.deviceId == bikeLock2.deviceId,
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
}

// MARK: - DFUHelperDelegate
extension BikeLock2SettingViewController: DFUHelperDelegate {
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

// MARK: INUI Add ShortcutVC Delegate
extension BikeLock2SettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is UnlockSesameIntent {
            L.d("[bk2][siri]這個有用到add setVoiceUnlock")
            bikeLock2.setVoiceUnlock(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: INUI Edit ShortcutVC Delegate
extension BikeLock2SettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                L.d("[bk2][siri]add editVoiceUnlock!!!")
                self.bikeLock2.removeVoiceUnlock()
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
