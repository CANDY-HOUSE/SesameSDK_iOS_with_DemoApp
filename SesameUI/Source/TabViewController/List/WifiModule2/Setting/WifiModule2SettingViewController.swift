//
//  WifiModule2SettingViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/9.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import CoreBluetooth

private let cellIdentifier = "cell"

struct WifiModule2SesameModel {
    var isWifiModule2Connected: Bool
    var sesame2Status: String
    var sesame2Key: String
}

class WifiModule2SettingViewController: CHBaseViewController, UICollectionViewDelegateFlowLayout {

//    var otaStartTime: Date!
    var wifiModuleDeviceModels = [WifiModule2SesameModel]()
    lazy var localDevices: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data.filter {
                    if $0 is CHSesame2 || $0 is CHSesameBot || $0 is CHSesameBike {
                        return true
                    } else {
                        return false
                    }
                }
            }
        }
        return chDevices
    }()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStackView: UIStackView!
    var uuidView: CHUIPlainSettingView!
    var versionView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var statusView: CHUIPlainSettingView!
    var versionTag = ""
    @IBOutlet var networkStatusView: UIView!
    @IBOutlet weak var networkStatusTitleLabel: UILabel! {
        didSet {
            networkStatusTitleLabel.text = "co.candyhouse.sesame2.wm2NetworkConnectionStatus".localized
        }
    }
    
    var addSesameButtonView: CHUIPlainSettingView!
    @IBOutlet weak var apImageView: UIImageView!
    @IBOutlet weak var apIndicator: UIActivityIndicatorView! {
        didSet {
            apIndicator.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            apIndicator.startAnimating()
        }
    }
    @IBOutlet weak var networkIndicatorLine: UIView! {
        didSet {
            networkIndicatorLine.backgroundColor = .sesame2Green
        }
    }
    @IBOutlet weak var iotIndicatorLine: UIView! {
        didSet {
            iotIndicatorLine.backgroundColor = .sesame2Green
        }
    }
    @IBOutlet weak var internatImageView: UIImageView!
    @IBOutlet weak var netIndicator: UIActivityIndicatorView! {
        didSet {
            netIndicator.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            netIndicator.startAnimating()
        }
    }
    @IBOutlet weak var iotImageView: UIImageView!
    @IBOutlet weak var iotIndicator: UIActivityIndicatorView! {
        didSet {
            iotIndicator.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            iotIndicator.startAnimating()
        }
    }
    var refreshControl: UIRefreshControl = UIRefreshControl()

    var wifiSSIDView: CHUIPlainSettingView!
    var wifiPasswordView: CHUIPlainSettingView!
    var wifiExclamationContainerView: UIView!
    var sesameExclamationContainerView: UIView!
    
    var ssidScanViewController: WifiModule2SSIDScanViewController?
    var isFromRegister: Bool = false
    fileprivate var dismissHandler: (()->Void)?
    var sesame2ListView = UITableView(frame: .zero)
    var sesame2ListViewHeight: NSLayoutConstraint!
    var wifiModule2: CHWifiModule2!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }
        
        arrangeSubViews()
        view.backgroundColor = .sesame2Gray
        sesame2ListView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        sesame2ListView.delegate = self
        sesame2ListView.dataSource = self
        sesame2ListView.isScrollEnabled = false
        
        if wifiModule2.deviceStatus.loginStatus == .logined {
            wifiModule2.getVersionTag() { result in
                switch result {
                case .success(let versionTag):
                    executeOnMainThread {
                        self.versionTag = versionTag.data
                        self.versionView.value = versionTag.data
                    }
                case .failure(_):
                    break
                }
            }
        }
        
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(onScanRequested), for: .valueChanged)
        showStatusViewIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wifiModule2.delegate = self
        if wifiModule2.deviceStatus == .receivedBle() {
            wifiModule2.connect() { _ in }
        }
//        wifiModule2.getCHDevices { _ in }
        wifiModuleDeviceModels = wifiModule2.sesame2Keys.keys.compactMap { key -> WifiModule2SesameModel? in
            guard let deviceStatus = wifiModule2.sesame2Keys[key],
                  let status = UInt8(deviceStatus),
                  let sesmae2LockStatus = WifiModule2Sesame2LockStatus(rawValue: status) else {
                return nil
            }
            return WifiModule2SesameModel(isWifiModule2Connected: sesmae2LockStatus != .disconnected, sesame2Status: sesmae2LockStatus.description, sesame2Key: key)
        }
        self.sesame2ListViewHeight.constant = CGFloat(self.wifiModuleDeviceModels.count) * 50
        self.sesame2ListView.reloadData()
        refreshUI()
        if isFromRegister {
            presentSSIDSelectionView()
            isFromRegister = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            dismissHandler?()
        }
    }
    
    func arrangeSubViews() {
        // MARK: Status View
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        // MARK: - ChangeName
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            let placeholder = wifiModule2.deviceName

            ChangeValueDialog.show(placeholder, title: "co.candyhouse.sesame2.EditWifiModule2Name".localized) { name in
                if name == "" {
                    self.view.makeToast("co.candyhouse.sesame2.EditWifiModule2Name".localized)
                    return
                }
                self.wifiModule2.setDeviceName(name)
                
                self.refreshUI()
                
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    listViewController.reloadTableView()
                }
            }
        }
        changeNameView.title = "co.candyhouse.sesame2.EditWifiModule2Name".localized
        changeNameView.value = wifiModule2.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: WiFi SSID View
        wifiSSIDView = CHUIViewGenerator.plain { [unowned self] button,_ in
            self.presentSSIDSelectionView()
        }
        wifiSSIDView.title = "co.candyhouse.sesame2.wifissid".localized
        wifiSSIDView.value = ""
        contentStackView.addArrangedSubview(wifiSSIDView)
        wifiExclamationContainerView = UIView(frame: .zero)
        let wifiSSIDExclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed))
        wifiExclamationContainerView.addSubview(wifiSSIDExclamation)
        wifiSSIDView.appendViewToTitle(wifiExclamationContainerView)
        wifiExclamationContainerView.autoLayoutWidth(20)
        wifiExclamationContainerView.autoLayoutHeight(20)
        wifiSSIDExclamation.autoLayoutWidth(20)
        wifiSSIDExclamation.autoLayoutHeight(20)
        wifiSSIDExclamation.autoPinCenterY()
        
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: WiFi Password View
        wifiPasswordView = CHUIViewGenerator.plain()
        wifiPasswordView.title = "co.candyhouse.sesame2.wifipassword".localized
        wifiPasswordView.value = ""
        
        contentStackView.addArrangedSubview(wifiPasswordView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thin))
        
        // MARK: - Network Status View
        contentStackView.addArrangedSubview(networkStatusView)
        networkStatusView.backgroundColor = .white
        networkStatusView.autoLayoutHeight(50)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thin))
        
        // MARK: Version
        versionView = CHUIViewGenerator.plain { [unowned self] button,_ in
            self.updateFirmware((button as! UIButton))
        }
        versionView.title = "co.candyhouse.sesame2.WM2OSUpdate".localized
        versionView.value = ""
        contentStackView.addArrangedSubview(versionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: UUID
        uuidView = CHUIViewGenerator.plain { [unowned self] _,_ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = uuidView.value
        }
        uuidView.title = "co.candyhouse.sesame2.UUID".localized
        uuidView.value = wifiModule2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.group))
        
        // MARK: Add Sesame Title
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = "co.candyhouse.sesame2.bindSesame2ToWifiModule2".localized
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop()
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Sesame2ListView
        contentStackView.addArrangedSubview(sesame2ListView)
        sesame2ListViewHeight = sesame2ListView.autoLayoutHeight(0)
        sesame2ListView.separatorColor = .lockGray
        
        // MARK: Add Sesame Buttom View
        addSesameButtonView = CHUIViewGenerator.plain { [unowned self] button,_ in
            if self.wifiModuleDeviceModels.count < 3 && self.wifiModule2.networkStatus?.isAPWork == true {
                self.addSesameTapped(button)
            }
        }
        if self.wifiModuleDeviceModels.count < 3 {
            addSesameButtonView.setColor(.darkText)
        } else {
            addSesameButtonView.setColor(.sesame2Gray)
        }
        addSesameButtonView.title = "co.candyhouse.sesame2.addSesameToWM2".localized
        sesameExclamationContainerView = UIView(frame: .zero)
        let sesameExclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed))
        sesameExclamationContainerView.addSubview(sesameExclamation)
        addSesameButtonView.appendViewToTitle(sesameExclamationContainerView)
        sesameExclamationContainerView.autoLayoutWidth(20)
        sesameExclamationContainerView.autoLayoutHeight(20)
        sesameExclamation.autoLayoutWidth(20)
        sesameExclamation.autoLayoutHeight(20)
        sesameExclamation.autoPinCenterY()
        
        contentStackView.addArrangedSubview(addSesameButtonView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.group))

        // MARK: Share
//        let shareKeyView = CHUICallToActionView { [unowned self] sender in
//            let wifiModule2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.wifiModule2, keyLevel: .member)
//            self.navigationController?.pushViewController(wifiModule2QRCodeViewController, animated: true)
//        }
//        shareKeyView.title = "co.candyhouse.sesame2.ShareTheWifiModule2Key".localized
//        contentStackView.addArrangedSubview(shareKeyView)

        // MARK: Drop key
//        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.confirmTrashKey(sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheWifiModule2Key".localized
        contentStackView.addArrangedSubview(dropKeyView)
        
        // MARK: Drop Key Desc
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyDescContainer = UIView(frame: .zero)
        let dropKeyDescLabel = UILabel(frame: .zero)
        dropKeyDescLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.WifiModule2".localized, "co.candyhouse.sesame2.WifiModule2".localized, "co.candyhouse.sesame2.WifiModule2".localized])
        dropKeyDescLabel.textColor = UIColor.placeHolderColor
        dropKeyDescLabel.minimumScaleFactor = 0.1
        dropKeyDescLabel.adjustsFontSizeToFitWidth = true
        dropKeyDescLabel.numberOfLines = 3
        dropKeyDescContainer.addSubview(dropKeyDescLabel)
        dropKeyDescLabel.autoPinLeading(constant: 10)
        dropKeyDescLabel.autoPinTrailing(constant: -10)
        dropKeyDescLabel.autoPinTop()
        dropKeyDescLabel.autoPinBottom()
        contentStackView.addArrangedSubview(dropKeyDescContainer)

        #if DEBUG
        // MARK: Reset Sesame
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.confirmReset(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetWifiModule2".localized
        contentStackView.addArrangedSubview(resetKeyView)
        #endif
    }
    
    func confirmTrashKey(_ sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.TrashTheWifiModule2Key".localized,
                                            style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            self.wifiModule2.dropUserKey { result in
                if case let .failure(error) = result {
                    L.d(error.errorDescription())
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
//                        self.view.makeToast(error.errorDescription())
                    }
                } else {
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.navigationController?.popViewController(animated: false)
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
    
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                      style: .destructive) { _ in
            self.resetWifiModule2()
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
    
    func resetWifiModule2() {
        ViewHelper.showLoadingInView(view: self.view)
        self.wifiModule2.resetUserKey { result in
            if case let .failure(error) = result {
                L.d(error.errorDescription())
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
//                    self.view.makeToast(error.errorDescription())
                }
            } else {
                executeOnMainThread {
                    self.navigationController?.popViewController(animated: false)
                }
            }
        }
    }
    
    func refreshUI() {
        if let mechSetting = wifiModule2.mechSetting {
            self.wifiSSIDView.value = mechSetting.wifiSSID ?? ""
            self.wifiPasswordView.value = mechSetting.wifiPassword ?? ""
        }
        
        if let networkStatus = wifiModule2.networkStatus {
            var wifiColor: UIColor
            if networkStatus.isAPWork == true {
                wifiColor = UIColor.sesame2Green
            } else {

                wifiColor = UIColor.lockGray
            }
            apImageView.image = UIImage.SVGImage(named: "wifi", fillColor: wifiColor)
            
            var networkColor: UIColor
            if networkStatus.isNetwork == true {
                networkColor = UIColor.sesame2Green
            } else {
                networkColor = UIColor.lockGray
            }
            internatImageView.image = UIImage.SVGImage(named: "world", fillColor: networkColor)
            
            var iotColor: UIColor
            if networkStatus.isIoTWork {
                iotColor = UIColor.sesame2Green
            } else {
                iotColor = UIColor.lockGray
            }
            iotImageView.image = UIImage.SVGImage(named: "checked", fillColor: iotColor)
            
            apIndicator.isHidden = networkStatus.isBindingAPWork ? false : true
            netIndicator.isHidden = networkStatus.isConnectingNetwork ? false : true
            iotIndicator.isHidden = networkStatus.isConnectingIoT ? false : true
            
            networkIndicatorLine.isHidden = !networkStatus.isNetwork
            iotIndicatorLine.isHidden = !networkStatus.isIoTWork
            
            wifiExclamationContainerView.isHidden = networkStatus.isAPWork
            
            if wifiModule2.networkStatus?.isAPWork == true {
                addSesameButtonView.setColor(.darkText)
            } else {
                addSesameButtonView.setColor(.sesame2Gray)
            }
            
            if wifiModuleDeviceModels.count >= 3 {
                addSesameButtonView.setColor(.sesame2Gray)
            }
        }
        sesameExclamationContainerView.isHidden = wifiModuleDeviceModels.count > 0 || wifiModule2.networkStatus?.isAPWork == false
        changeNameView.value = wifiModule2.deviceName
    }
    
    @IBAction func networkStatusDidTapped(_ sender: Any) {
    }
    
    @objc func updateFirmware(_ button: UIButton) {
        let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.WM2OSUpdate".localized, preferredStyle: .actionSheet)
        let ok = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized, style: .default) { _ in
            self.versionTag = ""
            self.wifiModule2.updateFirmware { result in
                if case let .failure(error) = result {
                    L.d(error.errorDescription())
//                    executeOnMainThread {
//                        self.view.makeToast(error.errorDescription())
//                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel) { _ in
            
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = button
        present(alertController, animated: true, completion: nil)
    }
    
    func presentSSIDSelectionView() {
        ssidScanViewController = WifiModule2SSIDScanViewController.instance()
        ssidScanViewController?.delegate = self
        present(ssidScanViewController!.navigationController!, animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        wifiModule2.disconnect(result: {_ in})
        self.dismissHandler?()
    }
}

// MARK: - WifiModule2SSIDScanViewControllerDelegate
extension WifiModule2SettingViewController: WifiModule2SSIDScanViewControllerDelegate {
    func onSSIDSelected(_ ssid: String) {
        ViewHelper.showLoadingInView(view: self.ssidScanViewController?.view)
        wifiModule2.setWifiSSID(ssid) { setResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.ssidScanViewController?.view)
                if case let .failure(error) = setResult {
                    self.ssidScanViewController?.view.makeToast(error.errorDescription())
                } else {
                    self.wifiSSIDView.value = ssid
                    self.ssidScanViewController?
                        .navigationController?
                        .presentCHAlertWithPlaceholder(title: ssid,
                                                       placeholder: "",
                                                       hint: "co.candyhouse.sesame2.enterSSIDPassword".localized) { password in
                            self.setWifiPasswordAndConnect(password)
                        }
                }
            }
        }
    }
    
    private func setWifiPasswordAndConnect(_ password: String) {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.ssidScanViewController?.view)
        }
        self.wifiModule2.setWifiPassword(password) { setPasswordResult in
            if case let .failure(error) = setPasswordResult {
                executeOnMainThread {
                    self.ssidScanViewController?.view.makeToast("\(error.errorDescription())")
                    ViewHelper.hideLoadingView(view: self.ssidScanViewController?.view)
                }
            } else {
                executeOnMainThread {
                    self.ssidScanViewController?.dismiss(animated: true, completion: {
                        self.wifiModule2.connectWifi { connectWifiResult in
                            if case .failure(_) = connectWifiResult {
                                executeOnMainThread {
                                    let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.connectWifiFailed".localized, preferredStyle: .alert)
                                    alertController.addAction(.init(title: "co.candyhouse.sesame2.OK".localized, style: .default, handler: nil))
                                    self.present(alertController, animated: true, completion: nil)
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    @objc func onScanRequested() {
        executeOnMainThread {
            self.wifiModule2.scanWifiSSID { _ in }
        }
    }
    
    func showStatusViewIfNeeded() {
        if CHBleManager.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if wifiModule2.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = wifiModule2.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
    }
}

// MARK: - CHWifiModule2Delegate
extension WifiModule2SettingViewController: CHWifiModule2Delegate {
    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
    
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHSesame2Status) {
        if status == .receivedBle() {
            device.connect() { _ in
                
            }
        }
        
        if status.loginStatus == .logined {
            if versionTag == "" {
                wifiModule2.getVersionTag() { result in
                    switch result {
                    case .success(let versionTag):
                        executeOnMainThread {
                            self.versionTag = versionTag.data
                            self.versionView.value = versionTag.data
                        }
                    case .failure(_):
                        break
                    }
                }
            }
        }

        executeOnMainThread {
            self.refreshUI()
            self.showStatusViewIfNeeded()
        }
    }
    
    func onNetworkStatusChanged(device: CHWifiModule2, status: CHWifiModule2NetworkStatus) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
    
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String: String]) {
        wifiModuleDeviceModels = sesame2keys.keys.compactMap { key -> WifiModule2SesameModel? in
            guard let deviceStatus = sesame2keys[key],
                  let status = UInt8(deviceStatus),
                  let sesmae2LockStatus = WifiModule2Sesame2LockStatus(rawValue: status) else {
                return nil
            }
            return WifiModule2SesameModel(isWifiModule2Connected: sesmae2LockStatus != .disconnected, sesame2Status: sesmae2LockStatus.description, sesame2Key: key)
        }
        executeOnMainThread {
            self.sesame2ListViewHeight.constant = CGFloat(self.wifiModuleDeviceModels.count) * 50
            self.sesame2ListView.reloadData()
            self.refreshUI()
        }
    }
    
    func onOTAProgress(device: CHWifiModule2, percent: UInt8) {
        guard self.changeNameView != nil else {
            return
        }
        
        executeOnMainThread {
//            if percent == UInt8(1) {
//                self.otaStartTime = Date()
//            } else if percent == UInt8(99) {
//                let period = Date().timeIntervalSince1970 - self.otaStartTime.timeIntervalSince1970
//                L.d("OTA time \(period)")
//            }
            self.versionView.value = "\(percent) %"
        }
    }
    
    func onScanWifiSID(device: CHWifiModule2, ssid: SSID) {
        guard self.changeNameView != nil else {
            return
        }
        executeOnMainThread {
            if self.ssidScanViewController!.ssids.contains(ssid) == false {
                self.ssidScanViewController!.ssids.append(ssid)
            } else if let oldSSID = self.ssidScanViewController!.ssids.filter({ $0 == ssid }).first, ssid.rssi > oldSSID.rssi {
                self.ssidScanViewController!.ssids.removeAll(where: { $0 == ssid })
                self.ssidScanViewController!.ssids.append(ssid)
            }
            if let settingSSID = device.mechSetting?.wifiSSID {
                self.ssidScanViewController!.ssids = self.ssidScanViewController!.ssids.sorted { left, right -> Bool in
                    if left.name == settingSSID {
                        return true
                    } else if right.name == settingSSID {
                        return false
                    } else {
                        return left.rssi > right.rssi
                    }
                }
            }
            self.ssidScanViewController!.reloadTableView()
        }
    }
}

extension WifiModule2SettingViewController {
    static func instanceWithWifiModule2(_ wifiModule2: CHWifiModule2, isFromRegister: Bool = false, dismissHandler: (()->Void)? = nil) -> WifiModule2SettingViewController {
        let wifiModule2SettingViewController = WifiModule2SettingViewController(nibName: "WifiModule2SettingViewController", bundle: nil)
        wifiModule2SettingViewController.wifiModule2 = wifiModule2
        wifiModule2SettingViewController.dismissHandler = dismissHandler
        wifiModule2SettingViewController.isFromRegister = isFromRegister
        wifiModule2SettingViewController.hidesBottomBarWhenPushed = true
        return wifiModule2SettingViewController
    }
}
