//
//  WifiModule2SettingViewController.swift
//  SesameUI
//
//  Created by JOi Chao on 2023/06/08.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF
import CoreBluetooth


class WifiModule2SettingViewController: CHBaseViewController, UICollectionViewDelegateFlowLayout, DeviceControllerHolder {

    var wifiModuleDeviceModels = [String]()
    lazy var localDevices: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data
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
    
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!

    var wifiModule2: CHWifiModule2! {
        didSet {
            device = wifiModule2
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        L.d("[wm2][ViewDidLoad]")
        
        arrangeSubViews()
        view.backgroundColor = .sesame2Gray
        sesame2ListView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        wifiModuleDeviceModels = wifiModule2.sesame2Keys.keys.compactMap { key -> String? in
            return key
        }
        L.d("[wm2]",wifiModuleDeviceModels)
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

        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = wifiModule2.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))


        // MARK: - ChangeName
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
                            CHUserAPIManager.shared.putCHUserKey(userKey) { _ in
                                
                            }
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
        
        // MARK: WiFi SSID View
        wifiSSIDView = CHUIViewGenerator.plain { [unowned self] button,_ in
            self.presentSSIDSelectionView()
        }
        wifiSSIDView.title = "co.candyhouse.sesame2.wifissid".localized
        wifiSSIDView.value = ""
        contentStackView.addArrangedSubview(wifiSSIDView)
        wifiExclamationContainerView = UIView(frame: .zero)
        let wifiSSIDExclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed))
        wifiSSIDExclamation.contentMode = .scaleAspectFit
        wifiExclamationContainerView.addSubview(wifiSSIDExclamation)
        wifiSSIDView.appendViewToTitle(wifiExclamationContainerView)
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
        titleLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        titleLabel.lineBreakMode = .byWordWrapping // 按單詞換行
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
            if self.wifiModuleDeviceModels.count < 3 && (self.wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true {
                let wifiModule2KeysListViewController = WifiModule2KeysListViewController.instance { [unowned self] device in
                    self.navigationController?.popViewController(animated: true)
                    self.wifiModule2.insertSesame(device) { result in
                        executeOnMainThread {
                            if case let .failure(error) = result {
                                self.view.makeToast(error.errorDescription())
                            }
                        }
                    }
                }
                self.navigationController?.pushViewController(wifiModule2KeysListViewController, animated: true)
            }
        }
        if self.wifiModuleDeviceModels.count <  3 {
            addSesameButtonView.setColor(.darkText)
        } else {
            addSesameButtonView.setColor(.sesame2Gray)
        }
        
        addSesameButtonView.title = "co.candyhouse.sesame2.addSesameToWM2".localized
        sesameExclamationContainerView = UIView(frame: .zero)
        let sesameExclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed)) // ！驚嘆號！
        sesameExclamation.contentMode = .scaleAspectFit
        sesameExclamationContainerView.addSubview(sesameExclamation)
        addSesameButtonView.appendViewToTitle(sesameExclamationContainerView)
        sesameExclamation.autoLayoutWidth(20)
        sesameExclamation.autoLayoutHeight(20)
        sesameExclamation.autoPinCenterY()
        
        contentStackView.addArrangedSubview(addSesameButtonView)
        contentStackView.addArrangedSubview(CHUIViewGenerator.seperatorWithStyle(.group))


        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmDropKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheWifiModule2Key".localized
        contentStackView.addArrangedSubview(dropKeyView)
        
        // MARK: Drop Key Desc
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        let dropKeyDescContainer = UIView(frame: .zero)
        let dropKeyDescLabel = UILabel(frame: .zero)
        dropKeyDescLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.WifiModule2".localized, "co.candyhouse.sesame2.WifiModule2".localized, "co.candyhouse.sesame2.WifiModule2".localized])
        dropKeyDescLabel.textColor = UIColor.placeHolderColor
        dropKeyDescLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        dropKeyDescLabel.lineBreakMode = .byWordWrapping // 按單詞換行
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
            self.prepareConfirmResetKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
                self.dismissHandler?()
            }
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetWifiModule2".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif
    }
    
    func refreshUI() {
        if let mechSetting = wifiModule2.mechSetting {
            self.wifiSSIDView.value = mechSetting.wifiSSID ?? ""
            self.wifiPasswordView.value = mechSetting.wifiPassword ?? ""
        }


        if let networkStatus = (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus) {
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
            if networkStatus.isIoTWork == true {
                iotColor = UIColor.sesame2Green
            } else {
                iotColor = UIColor.lockGray
            }
            iotImageView.image = UIImage.SVGImage(named: "checked", fillColor: iotColor)
            
            apIndicator.isHidden = networkStatus.isBindingAPWork ? false : true
            netIndicator.isHidden = networkStatus.isConnectingNetwork ? false : true
            iotIndicator.isHidden = networkStatus.isConnectingIoT ? false : true
            
            networkIndicatorLine.isHidden = !(networkStatus.isNetwork ?? true)
            iotIndicatorLine.isHidden = !(networkStatus.isIoTWork ?? true)
            
            wifiExclamationContainerView.isHidden = networkStatus.isAPWork == true
            
            if (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true {
                addSesameButtonView.setColor(.darkText)
            } else {
                addSesameButtonView.setColor(.sesame2Gray)
            }
            
            if wifiModuleDeviceModels.count >= 3 {
                addSesameButtonView.setColor(.sesame2Gray)
            }
        }
        sesameExclamationContainerView.isHidden = wifiModuleDeviceModels.count > 0 || (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == false
        addSesameButtonView.hidePlusLable(wifiModuleDeviceModels.count == 0 || (wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == false)
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
        if isMovingFromParent {
            wifiModule2.disconnect(result: {_ in})
            self.dismissHandler?()
        }
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
}

// MARK: - CHWifiModule2Delegate
extension WifiModule2SettingViewController: CHWifiModule2Delegate {

    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        executeOnMainThread {
            self.refreshUI()
        }
    }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus,shadowStatus:CHDeviceStatus?) {
        if status == .receivedBle() {
            device.connect() { _ in }
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

    func onMechStatus(device: CHDevice) {
        executeOnMainThread {
            self.refreshUI()
        }
    }

    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String: String]) {
        wifiModuleDeviceModels = sesame2keys.keys.compactMap { key -> String? in
            return key
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
            self.versionView.value = "\(percent) %"
        }
    }
    
    func onScanWifiSID(device: CHWifiModule2, ssid: CHSSID) {
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


extension WifiModule2SettingViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        wifiModuleDeviceModels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wifiModuleDeviceModel = wifiModuleDeviceModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        cell.selectionStyle = .none
        let foundDevice = localDevices.filter {
            $0.deviceId.uuidString == wifiModuleDeviceModel
        }.first
        if foundDevice != nil {
            cell.textLabel?.text = foundDevice?.deviceName
        } else {
            cell.textLabel?.text = wifiModuleDeviceModel
        }
        return cell
    }

    func image(_ image: UIImage, withSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = withSize.width  / image.size.width
        let heightRatio = withSize.height / image.size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    // wm2刪除ss5 pro
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delete = UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized,
                                            style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            let sesame2 = self.wifiModuleDeviceModels[indexPath.row]
            self.wifiModule2.removeSesame(tag: sesame2) { result in
                executeOnMainThread {
                    if case let .failure(error) = result {
                        self.view.makeToast(error.errorDescription())
                    } else {
                        self.wifiModuleDeviceModels.removeAll { $0 == sesame2 }
                        self.sesame2ListView.reloadData()
                    }
                    ViewHelper.hideLoadingView(view: self.view)
                }
            }

        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(delete)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }

}
