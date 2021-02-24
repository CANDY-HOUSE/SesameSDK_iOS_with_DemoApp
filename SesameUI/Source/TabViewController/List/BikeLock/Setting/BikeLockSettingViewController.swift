//
//  BikeLockSettingViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import iOSDFULibrary
import CoreBluetooth

class BikeLockSettingViewController: CHBaseViewController {
    
    // MARK: - Data model
    var bikeLock: CHSesameBike!
    
    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var uuidView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var statusView: CHUIPlainSettingView!
    
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
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: bikeLock)
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
        changeNameView.value = bikeLock.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
            self.presentQRCodeSharingView(sender: sender as! UIButton)
        }
        shareKeyView.title = "co.candyhouse.sesame2.ShareTheKey".localized
        contentStackView.addArrangedSubview(shareKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)

            let confirmAction = UIAlertAction(title: DFUHelper.bikeLockApplicationDfuFileName()!,
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
        dfuView.value = version ?? ""
        contentStackView.addArrangedSubview(dfuView)
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
            self.trashKey(sender: sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        
        // MARK: Drop Key Desc
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.BikeLock".localized, "co.candyhouse.sesame2.BikeLock".localized, "co.candyhouse.sesame2.BikeLock".localized])
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
        dfuView.value = version ?? ""
        changeNameView.value = bikeLock.deviceName
    }
    
    // MARK: getVersionTag
    private func getVersionTag() {
        bikeLock.getVersionTag { result in
            switch result {
            case .success(let status):
                self.version = status.data
                executeOnMainThread {
                    self.refreshUI()
                }
            case .failure(let error):
                L.d(error.errorDescription())
//                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: changeName
    func changeName() {
        ChangeValueDialog.show(bikeLock.deviceName, title: "co.candyhouse.sesame2.EditSesameName".localized) { name in
            if name == "" {
                self.view.makeToast("co.candyhouse.sesame2.EditSesameName".localized)
                return
            }
            self.bikeLock.setDeviceName(name)
            
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
            let deviceKey = self.bikeLock.getKey()
            let qrCode = URL.qrCodeURLFromDeviceKey(deviceKey!, deviceName: self.bikeLock.deviceName)
            let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.bikeLock, qrCode: qrCode!)
            self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
        }
    }
    
    // MARK: OTA
    func dfuSesame2(_ bikeLock: CHSesameBike) {
        DFUCenter.shared.dfuDevice(bikeLock, delegate: self)
        self.version = nil
    }
    
    // MARK: trashKey
    func trashKey(sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.TrashTheKey".localized,
                                     style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            
            self.bikeLock.dropUserKey { result in
                if case let .failure(error) = result {
                    L.d(error.errorDescription())
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
//                        self.view.makeToast(error.errorDescription())
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
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                            style: .cancel) { (action) in
            
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                      style: .destructive) { _ in
            self.resetBikeLock()
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
    public func resetBikeLock() {
        ViewHelper.showLoadingInView(view: view)
        bikeLock?.resetUserKey({ result in
            if case let .failure(error) = result {
                L.d(error.errorDescription())
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
//                    self.view.makeToast(error.errorDescription())
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
        } else if bikeLock.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = bikeLock.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
    }
}

// MARK: - CHSesame2Delegate
extension BikeLockSettingViewController: CHSesameBikeDelegate {
    public func onBleDeviceStatusChanged(device: SesameLock,
                                         status: CHSesame2Status,
                                         shadowStatus: CHSesame2ShadowStatus?) {
        
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
