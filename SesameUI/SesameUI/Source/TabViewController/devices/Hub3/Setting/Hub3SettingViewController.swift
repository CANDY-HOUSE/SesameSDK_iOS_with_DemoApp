//
//  Hub3SettingViewController.swift
//  SesameUI
//
//  Created by eddy on 2024/1/6.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import AWSMobileClientXCF
import CoreBluetooth


class Hub3SettingViewController: CHBaseViewController, UICollectionViewDelegateFlowLayout, DeviceControllerHolder {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStackView: UIStackView!
    var uuidView: CHUIPlainSettingView!
    var versionView: CHUIPlainSettingView!
    var sliderView: CHUISliderSettingView!
    var changeNameView: CHUIPlainSettingView!
    var statusView: CHUIPlainSettingView!
    var versionTag = ""
    var netVersionTag = ""
    
    @IBOutlet var networkStatusView: UIView!
    @IBOutlet weak var networkStatusTitleLabel: UILabel! {
        didSet {
            networkStatusTitleLabel.text = "co.candyhouse.sesame2.wm2NetworkConnectionStatus".localized
        }
    }
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
    var deviceMembersView: KeyCollectionViewController!
    var friendListHeight: NSLayoutConstraint!

    var wifiSSIDView: CHUIPlainSettingView!
    var wifiPasswordView: CHUIPlainSettingView!
    var sesameExclamationContainerView: UIView!
    
    var ssidScanViewController: WifiModule2SSIDScanViewController?
    var isFromRegister: Bool = false
    fileprivate var dismissHandler: (()->Void)?
    
    var wifiModuleDeviceModels = [String]()
    var addSesameButtonView: CHUIPlainSettingView!
    var sesame2ListView = UITableView(frame: .zero)
    var sesame2ListViewHeight: NSLayoutConstraint!
    
    var wifiModuleIRModels = [IRRemote]()
    var addIRKeysButtonView: CHUIPlainSettingView!
    var irKeysListView = UITableView(frame: .zero)
    var irKeysViewHeight: NSLayoutConstraint!
    var irKeysAddHint: UIView!
    
    var wifiModule2: CHHub3! {
        didSet {
            self.device = wifiModule2
        }
    }
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!

    // MARK: life cycle
    deinit {
        wifiModule2.disconnect(result: {_ in })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        L.d("[wm2][ViewDidLoad]")
        view.backgroundColor = .sesame2Gray
        arrangeSubViews()
        configureSesameTableView()
        configureIRKeysTableView()
        
        let refreshControl: UIRefreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        showStatusViewIfNeeded()
        checkOSUpgradeByNetworkIfNeeded()
        fetchIrDevices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wifiModule2.delegate = self
        if wifiModule2.deviceStatus == .receivedBle() { wifiModule2.connect() { _ in } }
        //        wifiModule2.getCHDevices { _ in }
        refreshSesameKeys()
        refreshIRKeys()
        refreshUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFromRegister {
//            presentSSIDSelectionView()
            isFromRegister = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            dismissHandler?()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            self.dismissHandler?()
        }
    }
    
    @objc func reloadFriends() {
        deviceMembersView?.getMembers()
        scrollView.refreshControl?.endRefreshing()
    }
    
    func arrangeSubViews() {
        // MARK: Status View
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        
        // MARK: Group
        if AWSMobileClient.default().currentUserState == .signedIn, wifiModule2.keyLevel != KeyLevel.guest.rawValue {
            deviceMembersView = KeyCollectionViewController.instanceWithDevice(wifiModule2)
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
            let placeholder = wifiModule2.deviceName
            ChangeValueDialog.show(placeholder, title: "co.candyhouse.sesame2.EditName".localized) { name in
                if name == "" {
                    self.view.makeToast("co.candyhouse.sesame2.EditName".localized)
                    return
                }
                self.wifiModule2.setDeviceName(name)
                if AWSMobileClient.default().currentUserState == .signedIn {
                    var userKey = CHUserKey.fromCHDevice(self.wifiModule2)
                    CHUserAPIManager.shared.getSubId { subId in
                        if let subId = subId {
                            userKey.subUUID = subId
                            CHUserAPIManager.shared.putCHUserKey(userKey) { _ in }
                        }
                    }
                }
                self.refreshUI()
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    listViewController.reloadTableView()
                }
            }
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = wifiModule2.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: 分享鑰匙
        if wifiModule2.keyLevel == KeyLevel.owner.rawValue || wifiModule2.keyLevel == KeyLevel.manager.rawValue {
            let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
                modalSheetToQRControlByRoleLevel(device: self.wifiModule2, sender: sender as? UIView) { isComplete in
                    if isComplete {
                        self.deviceMembersView?.getMembers()
                    }
                }
            }
            shareKeyView.title = "co.candyhouse.sesame2.ShareManagementView".localized
            contentStackView.addArrangedSubview(shareKeyView)
        }
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = wifiModule2.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: WiFi SSID View
        wifiSSIDView = CHUIViewGenerator.plain { [unowned self] button,_ in
            self.presentSSIDSelectionView()
        }
        wifiSSIDView.title = "co.candyhouse.sesame2.wifissid".localized
        wifiSSIDView.value = ""
        contentStackView.addArrangedSubview(wifiSSIDView)
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
        
        // MARK: LedDuty
        sliderView = CHUIViewGenerator.slider(
            defaultValue: 100,
            maximumValue: 100,
            minimumValue: 0.0,
            contentWidth: 200,
            { [weak self] slider, event in
                guard let self = self, let slider = slider as? UISlider else { return }
                let brightness = Int(slider.value)
                self.sliderView.updateBubble(withValue: self.formatBrightnessText(brightness))
            },
            { [weak self] slider, event in
                guard let self = self, let slider = slider as? UISlider else { return }
                self.handleHub3BrightnessSliderChange(slider: slider)
            }
        )
        sliderView.title = "LED 🔆"
        sliderView.slider.tintColor = .lockGreen
        sliderView.slider.thumbTintColor = .lockGreen
        sliderView.isSliderHidden = true
        contentStackView.addArrangedSubview(sliderView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        if wifiModule2.deviceStatus.loginStatus == .logined{
            self.setonHub3Brightness(device: wifiModule2)
        }
        
        // MARK: UUID
        uuidView = CHUIViewGenerator.plain { [unowned self] _,_ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = uuidView.value
        }
        uuidView.title = "co.candyhouse.sesame2.UUID".localized
        uuidView.value = wifiModule2.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thick))
        
        // MARK: matter
        let matterView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] _,_ in
//            UIApplication.shared.open(URL.init(string: "com.apple.home://")!)
            self.navigationController?.pushViewController(QRCodeViewController.instanceWithMatterPairingCode(device, dismissHandler: nil), animated: true)
        }
        matterView.title = "Matter"
        contentStackView.addArrangedSubview(matterView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thick))

        // MARK: ssm keys
        configureAddSesame()
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thick))
        
        // MARK: ir keys
        configureAddIRKeys()
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.thick))
        
        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmDropKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
        }
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized,arguments: [modelView.value])
        contentStackView.addArrangedSubview(dropKeyView)
        
        // MARK: Drop Key Desc
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyDescContainer = UIView(frame: .zero)
        CHUIViewGenerator.label(String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: [wifiModule2.deviceName, wifiModule2.deviceName, wifiModule2.deviceName]), superTuple: (dropKeyDescContainer, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)))
        contentStackView.addArrangedSubview(dropKeyDescContainer)
        
#if DEBUG
        // MARK: Reset Sesame
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmResetKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetHub3Module".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif
    }
    
    func refreshUI() {
        if let mechSetting = wifiModule2.mechSetting {
            self.wifiSSIDView.value = mechSetting.wifiSSID ?? ""
            self.wifiPasswordView.value = mechSetting.wifiPassword ?? ""
        }
        if let networkStatus = (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus) {
            apImageView.image = UIImage.SVGImage(named: "wifi", fillColor: networkStatus.isAPWork == true || networkStatus.isIoTWork == true ? UIColor.sesame2Green : UIColor.lockGray)
            internatImageView.image = UIImage.SVGImage(named: "world", fillColor: networkStatus.isNetwork == true || networkStatus.isIoTWork == true ? UIColor.sesame2Green : UIColor.lockGray)
            iotImageView.image = UIImage.SVGImage(named: "checked", fillColor: networkStatus.isIoTWork == true ? UIColor.sesame2Green : UIColor.lockGray)
            apIndicator.isHidden = networkStatus.isBindingAPWork ? false : true
            netIndicator.isHidden = networkStatus.isConnectingNetwork ? false : true
            iotIndicator.isHidden = networkStatus.isConnectingIoT ? false : true
            networkIndicatorLine.isHidden = !(networkStatus.isNetwork ?? true || networkStatus.isIoTWork ?? true)
            iotIndicatorLine.isHidden = !(networkStatus.isIoTWork ?? true)
            wifiSSIDView.exclamation.isHidden = (networkStatus.isAPWork ?? false || networkStatus.isNetwork ?? false || networkStatus.isIoTWork ?? false)
            addSesameButtonView.setColor((wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true ? .darkText : .sesame2Gray)
            addIRKeysButtonView.setColor((wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true ? .darkText : .sesame2Gray)
            if wifiModuleDeviceModels.count > 4 {
                addSesameButtonView.setColor(.sesame2Gray)
            }
        }
        sesameExclamationContainerView.isHidden = wifiModuleDeviceModels.count > 0 || (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == false
        changeNameView.value = wifiModule2.deviceName
    }
    
    func setonHub3Brightness(device: CHHub3){
        let progressValue = Float(device.hub3Brightness) / 255.0 * 100
        L.d("sf","progressValue: \(progressValue)")
        
        executeOnMainThread {
            self.sliderView.slider.value = progressValue
            self.sliderView.updateBubble(withValue: self.formatBrightnessText(Int(progressValue)))
            self.sliderView.isSliderHidden = false
        }
    }
    
    private func handleHub3BrightnessSliderChange(slider: UISlider) {
        let progressTouch = UInt8((slider.value / 100.0 * 255).rounded())
        L.d("sf", "progressTouch=\(progressTouch)")
        
        self.sliderView.updateBubble(withValue: self.formatBrightnessText(Int(progressTouch)))
        
        if let wifiModule = self.wifiModule2 {
            wifiModule.setHub3Brightness(brightness: progressTouch) { result in
                L.d("sf", "Hub 3 setting success...")
            }
        } else {
            L.d("sf", "wifiModule2 is nil")
        }
    }
    
    private func formatBrightnessText(_ brightness: Int) -> String {
        return "co.candyhouse.sesame2.face.brightness".localized + " \(brightness)%"
    }
    
    @IBAction func networkStatusDidTapped(_ sender: Any) {
    }
    
    @objc func updateFirmware(_ button: UIButton) {
        modalSheet(AlertModel(title: nil, message: "co.candyhouse.sesame2.SesameOSUpdate".localized, sourceView: button, items: [
            AlertItem(title: "co.candyhouse.sesame2.OK".localized, style: .default, handler: { [unowned self] _ in
                self.versionTag = ""
                self.wifiModule2.updateFirmware { [weak self] result in
                    if case let .failure(error) = result {
                        L.d(error.errorDescription())
                        executeOnMainThread {
                            self?.view.makeToast(error.errorDescription())
                        }
                    }
                }
            }),
            AlertItem.cancelItem()
        ]))
    }
    
    func presentSSIDSelectionView() {
        ssidScanViewController = WifiModule2SSIDScanViewController.instance()
        ssidScanViewController?.delegate = self
        present(ssidScanViewController!.navigationController!, animated: true, completion: nil)
    }
    
    //bug【1001351】iOS 与 Android 双端一致：在进入详情界面时更新最新的红外设备列表
    func fetchIrDevices() {
        wifiModule2.fetchIRDevices { _ in }
    }
}

extension Hub3SettingViewController: KeyCollectionViewControllerDelegate {
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

// MARK: - WifiModule2SSIDScanViewControllerDelegate
extension Hub3SettingViewController: WifiModule2SSIDScanViewControllerDelegate {
    func onSSIDSelected(_ ssid: String) {
        ViewHelper.showLoadingInView(view: self.ssidScanViewController?.view)
        wifiModule2.setWifiSSID(ssid) { setResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.ssidScanViewController?.view)
                if case let .failure(error) = setResult {
                    self.ssidScanViewController?.view.makeToast(error.errorDescription())
                } else {
                    self.wifiSSIDView.value = ssid
                    var pwd = ""
#if DEBUG
                    pwd = "55667788"
#endif
                    self.ssidScanViewController?
                        .navigationController?
                        .presentCHAlertWithPlaceholder(title: ssid,
                                                       placeholder: pwd,
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
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if wifiModule2.deviceStatus.loginStatus == .unlogined {
            self.statusView.title = wifiModule2.localizedDescription()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
    }
    
    func checkOSUpgradeIfNeeded() {
        guard versionTag == "" else { return }
        wifiModule2.getVersionTag() { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let versionTag):
                executeOnMainThread {
                    let versionStr = versionTag.data
                    if versionStr.hasPrefix("B") {
                        self.versionTag = String(versionStr.split(separator: ":").last!)
                    } else if versionStr.hasPrefix("N") {
                        self.netVersionTag = String(versionStr.split(separator: ":").last!)
                    }
                    self.compareIfNewest()
                }
            case .failure(_):
                // 无蓝牙通过网络返回的检查
                self.checkOSUpgradeByNetworkIfNeeded()
                break
            }
        }
    }
    
    func checkOSUpgradeByNetworkIfNeeded() {
        guard versionTag == "" else { return }
        guard let cVer = wifiModule2.status.v, cVer.isEmpty == false, wifiModule2.status.hub3LastFirmwareVer.isEmpty == false else {
            return
        }
        self.versionTag = cVer
        self.netVersionTag = wifiModule2.status.hub3LastFirmwareVer
        self.compareIfNewest()
    }
    
    func compareIfNewest() {
        executeOnMainThread {
            let latestVersion = self.netVersionTag
            let isnewest = self.versionTag.contains(latestVersion)
            self.versionView.value = "\(self.versionTag)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
            if !latestVersion.isEmpty {
                self.versionView.exclamation.isHidden = isnewest
            }
        }
    }
}

// MARK: - CHWifiModule2Delegate
extension Hub3SettingViewController: CHHub3Delegate {
    
    // MARK: onSesame2KeysChangedd
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String: String]) {
        ssm_didChangekeys(sesame2keys)
        ir_didChangekeys(sesame2keys)
    }
    
    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus,shadowStatus:CHDeviceStatus?) {
        if status == .receivedBle() {
            // 【eddy todo】点 ota升级时，硬件重启第一次立即连接时，会出现连接异常[硬件已经被连接上，但实际app的登录没有返回]，延时1s解决
            Debouncer(interval: 1.0).debounce { [weak self] in
                guard let _ = self else { return }
                device.connect() { _ in }
            }
        }
        if status.loginStatus == .logined {
            checkOSUpgradeIfNeeded()
        }
        executeOnMainThread {
            self.refreshUI()
            self.showStatusViewIfNeeded()
        }
    }
    
    func onMechStatus(device: CHDevice) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
    
    func onOTAProgress(device: CHWifiModule2, percent: UInt8) {
        guard self.changeNameView != nil else { return }
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.versionView.value = "\(percent) %"
            if percent == 100 {
                self.versionTag = ""
                if wifiModule2.deviceStatus.loginStatus == .unlogined {
                    checkOSUpgradeByNetworkIfNeeded()
                }
            }
        }
    }
    
    func onScanWifiSID(device: CHWifiModule2, ssid: CHSSID) {
        guard self.changeNameView != nil else { return }
        executeOnMainThread { [weak self] in
            guard let self = self, self.ssidScanViewController != nil else { return }
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
    
    func onHub3BrightnessReceive(device: CHHub3, brightness: UInt8) {
        L.d("sf","hub3连接后返回的亮度: \(device.hub3Brightness)")
        
        self.setonHub3Brightness(device: device)
    }
}

extension Hub3SettingViewController: UITableViewDelegate, UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == sesame2ListView ?
        ssm_tableView(tableView, numberOfRowsInSection: section) :
        ir_tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {     
        return tableView == sesame2ListView ?
        ssm_tableView(tableView, heightForRowAt: indexPath) :
        ir_tableView(tableView, heightForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView == sesame2ListView ?
        ssm_tableView(tableView, cellForRowAt: indexPath) :
        ir_tableView(tableView, cellForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return tableView == sesame2ListView ?
        ssm_tableView(tableView, didSelectRowAt: indexPath) :
        ir_tableView(tableView, didSelectRowAt: indexPath)
    }
}

extension Hub3SettingViewController {
    static func instanceWithHub3(_ hub3: CHHub3, isFromRegister: Bool = false, dismissHandler: (()->Void)? = nil) -> Hub3SettingViewController {
        let Hub3SettingViewController = Hub3SettingViewController(nibName: "Hub3SettingViewController", bundle: nil)
        Hub3SettingViewController.wifiModule2 = hub3
        Hub3SettingViewController.dismissHandler = dismissHandler
        Hub3SettingViewController.isFromRegister = isFromRegister
        Hub3SettingViewController.hidesBottomBarWhenPushed = true
        return Hub3SettingViewController
    }
}
