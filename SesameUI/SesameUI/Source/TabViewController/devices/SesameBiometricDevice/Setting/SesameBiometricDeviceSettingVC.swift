//
//  SesameBiometricDeviceSettingVC.swift
//  SesameUI
//  Touch + Touch Pro Setting View
//  Created by tse on 2023/5/16.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

extension SesameBiometricDeviceSettingVC: DFUHelperDelegate {
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
extension SesameBiometricDeviceSettingVC: KeyCollectionViewControllerDelegate {
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
extension SesameBiometricDeviceSettingVC {
    static func instance(_ device: CHSesameBasePro, dismissHandler: (()->Void)? = nil) -> SesameBiometricDeviceSettingVC {
        let vc = SesameBiometricDeviceSettingVC(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.mDevice = device
        vc.dismissHandler = dismissHandler
        return vc
    }
}

class SesameBiometricDeviceSettingVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate, DeviceControllerHolder {
    // MARK: DeviceControllerHolder impl
    let tag: String = "SesameBiometricDeviceSettingVC"
    var device: SesameSDK.CHDevice!
    
    var mDevice: CHSesameBasePro! {
        didSet {
            device = mDevice
        }
    }
    // MARK: getVersionTag
    private func getVersionTag() {
        mDevice.getVersionTag { result in
            switch result {
            case .success(let status):
                let fileName = DFUHelper.getDfuFileName(self.mDevice!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
                //                L.d("getVersionTag",status.data,latestVersion,isnewest)
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(_): break
                //                L.d(error.errorDescription())
            }
        }
    }
    
    func onRadarReceive(device: CHSesameConnector, payload: Data){
        self.setRadarUI(tag: "蓝牙回调", payload: payload)
    }
    
    func onSesame2KeysChanged(device: SesameSDK.CHSesameConnector, sesame2keys: [String : String]) {
        //L.d("[Tpro][onSesame2KeysChanged!!][sesame2Keys]",mDevice.sesame2Keys.keys)
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            mySesames = mDevice.sesame2Keys.keys.compactMap { $0 }
            self.showStatusViewIfNeeded()
            if self.mySesames.count <  3 {
                self.addSesameButtonView.setColor(.darkText)
            } else {
                self.addSesameButtonView.setColor(.sesame2Gray)
            }
            self.addSesameButtonView.exclamation.isHidden = (self.mySesames.count != 0)
        }
    }
    
    func onMechStatus(device: CHDevice) {
        executeOnMainThread { [self] in
            batteryView.value = "\(mDevice.mechStatus?.getBatteryPrecentage() ?? 0) %"
        }
    }
    
    func onBleDeviceStatusChanged(device: SesameSDK.CHDevice, status: SesameSDK.CHDeviceStatus, shadowStatus: SesameSDK.CHDeviceStatus?) {
        if status == .receivedBle() {
            device.connect() { _ in }
        }else if status.loginStatus == .logined {
            if versionStr == nil {
                getVersionTag()
            }
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
            if self.mySesames.count <  3 {
                self.addSesameButtonView.setColor(.darkText)
            } else {
                self.addSesameButtonView.setColor(.sesame2Gray)
            }
            self.addSesameButtonView.exclamation.isHidden = (self.mySesames.count != 0)
        }
    }
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            self.statusView.isHidden = false
        } else if self.mDevice.deviceStatus.loginStatus == .unlogined {
            self.statusView.isHidden = false
            self.statusView.title = self.mDevice.localizedDescription()
        } else {
            self.statusView.isHidden = true
        }
        return !statusView.isHidden
    }
    
    // MARK: - Data model
    lazy var localDevices: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data
            }
        }
        return chDevices
    }()
    var mySesames = [String](){
        didSet{
            executeOnMainThread {
                self.sesame2ListViewHeight.constant = CGFloat(self.mySesames.count) * 50
                self.sesame2ListView.reloadData()
            }
        }
    }
    
    // MARK: - Values for UI
    var versionStr: String? {
        didSet {
            executeOnMainThread {
                self.dfuView.value = self.versionStr ?? ""
            }
        }
    }
    var sesame2ListViewHeight: NSLayoutConstraint!
    
    // MARK: - UI Componets
    var friendListHeight: NSLayoutConstraint!
    var statusView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var addSesameButtonView: CHUIPlainSettingView!
    let batteryView = CHUIViewGenerator.plain ()
    var deviceMembersView: KeyCollectionViewController!
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var sesame2ListView = UITableView(frame: .zero)
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var dismissHandler: (()->Void)?
    var sliderView: CHUISliderSettingView!
    
    // 定义雷达灵敏度距离和固件值的查找表
    private let DISTANCE_TO_FIRMWARE_TABLE: [(distance: Int, firmware: Int)] = [
        (30, 116),
        (60, 44),
        (80, 31),
        (100, 23),
        (120, 21),
        (150, 20),
        (200, 17),
        (270, 16)
    ]
    
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
        sesame2ListView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        sesame2ListView.delegate = self
        sesame2ListView.dataSource = self
        sesame2ListView.isScrollEnabled = false
        self.arrangeSubviews()
    }
    
    @objc func reloadFriends() {
        deviceMembersView?.getMembers()
        refreshControl.endRefreshing()
    }
    
    deinit{
        mDevice.disconnect(){ _ in}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let mDevice = mDevice else {print("mDevice is nil");return}
        
        mDevice.delegate = self
        mySesames = mDevice.sesame2Keys.keys.compactMap { $0 }
        showStatusViewIfNeeded()
        
        if mDevice.deviceStatus == .receivedBle() {
            mDevice.connect() { _ in }
        }
        getVersionTag()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        let deviceModelName = mDevice.getDeviceName()
        
        // MARK: top status
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Group
        if AWSMobileClient.default().currentUserState == .signedIn, mDevice.keyLevel != KeyLevel.guest.rawValue {
            deviceMembersView = KeyCollectionViewController.instanceWithDevice(mDevice)
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
            ChangeValueDialog.show(mDevice.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
                self.mDevice.setDeviceName(name)
                self.changeNameView.value = name
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    listViewController.reloadTableView()
                }
                if AWSMobileClient.default().currentUserState == .signedIn {
                    var userKey = CHUserKey.fromCHDevice(self.mDevice)
                    CHUserAPIManager.shared.getSubId { subId in
                        if let subId = subId {
                            userKey.subUUID = subId
                            CHUserAPIManager.shared.putCHUserKey(userKey) { _ in}
                        }
                    }
                }
            }
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = mDevice.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Share
        if mDevice.keyLevel == KeyLevel.owner.rawValue || mDevice.keyLevel == KeyLevel.manager.rawValue  {
            let shareKeyView = CHUIViewGenerator.arrow(addtionalIcon: "qr-code") { [unowned self] sender,_ in
                self.presentQRCodeSharingView(sender: sender as! UIButton)
            }
            shareKeyView.title = "co.candyhouse.sesame2.ShareManagementView".localized
            contentStackView.addArrangedSubview(shareKeyView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        }
        
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Permission
        let permissionView = CHUIViewGenerator.plain()
        permissionView.title = "co.candyhouse.sesame2.Permission".localized
        permissionView.value = KeyLevel(rawValue: mDevice.keyLevel)!.description()
        contentStackView.addArrangedSubview(permissionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: NfcCards
        setupNFCCardView()
        
        // MARK: fingers
        setupFingerView()
        
        // MARK: PassCode
        setupPassCodeView()
        
        // MARK: face
        setupFaceView()
        
        // MARK: Palm
        setupPamView()
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",message: "co.candyhouse.sesame2.SesameOSUpdate".localized, preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized,
                                              style: .default) { _ in
                DFUCenter.shared.dfuDevice(self.mDevice, delegate: self)
                self.versionStr = nil
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
        
        // MARK: Battery View
        if(mDevice.productModel != .openSensor){
            batteryView.title = "co.candyhouse.sesame2.battery".localized
            contentStackView.addArrangedSubview(batteryView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = mDevice.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: Radar View
        if self.mDevice.productModel == .sesameFace || self.mDevice.productModel == .sesameFacePro {
            sliderView = CHUIViewGenerator.slider(
                defaultValue: 270,
                maximumValue: 270,
                minimumValue: 30.0,
                contentWidth: 200,
                { [weak self] slider, event in
                    guard let self = self, let slider = slider as? UISlider else { return }
                    let distance = Int(slider.value)
                    self.sliderView.updateBubble(withValue: self.formatDistanceText(distance))
                },
                { [weak self] slider, event in
                    guard let self = self, let slider = slider as? UISlider else { return }
                    self.handleRadarSliderChange(slider: slider)
                }
            )
            sliderView.title = "co.candyhouse.sesame2.face.radar".localized
            sliderView.slider.tintColor = .lockGreen
            sliderView.slider.thumbTintColor = .lockGreen
            sliderView.isSliderHidden = true
            contentStackView.addArrangedSubview(sliderView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
            if self.mDevice.deviceStatus.loginStatus == .logined{
                setRadarUI(tag: "UI初始化", payload: self.mDevice.radarPayload)
            }
            
            // MARK: Add Radar Hint
            let distanceDesContainer = UIView(frame: .zero)
            let distanceDesLabel = UILabel(frame: .zero)
            distanceDesLabel.text = "co.candyhouse.sesame2.face.radar_distance_description".localized
            distanceDesLabel.textColor = UIColor.placeHolderColor
            distanceDesLabel.numberOfLines = 0 // 設置為0時，允許無限換行
            distanceDesLabel.lineBreakMode = .byWordWrapping // 按單詞換行
            distanceDesContainer.addSubview(distanceDesLabel)
            distanceDesLabel.autoPinLeading(constant: 10)
            distanceDesLabel.autoPinTrailing(constant: -10)
            distanceDesLabel.autoPinTop()
            distanceDesLabel.autoPinBottom(constant: -20)
            contentStackView.addArrangedSubview(distanceDesContainer)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        }
        
        // MARK: 下面接钥匙管理
        // MARK: Add Sesame Hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.bindSesame2ToTouch".localized, arguments: [
            deviceModelName
        ])
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        titleLabel.lineBreakMode = .byWordWrapping // 按單詞換行
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop(constant: 5)
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: 连接设备(sesamelockers)列表
        contentStackView.addArrangedSubview(sesame2ListView)
        sesame2ListViewHeight = sesame2ListView.autoLayoutHeight(0)
        sesame2ListView.separatorColor = .lockGray
        
        // MARK: Add Sesame Buttom View
        addSesameButtonView = CHUIViewGenerator.plain { [unowned self] button,_ in
            let proKeysListVC = SesameBiometricDeviceKeysListVC.instance(device: self.mDevice)
            { device in
                self.navigationController?.popViewController(animated: true)
                self.mDevice.insertSesame(device) { _ in
                    L.d("[tpo][addSesameButtonView][insertSesame]添加成功？",device.deviceName)
                }
            }
            self.navigationController?.pushViewController(proKeysListVC, animated:true)
        }
        
        if self.mySesames.count <  3 {
            addSesameButtonView.setColor(.darkText)
        } else {
            addSesameButtonView.setColor(.sesame2Gray)
        }
        
        addSesameButtonView.exclamation.isHidden = self.mySesames.count > 0
        addSesameButtonView.title = "co.candyhouse.sesame2.addSesameToWM2".localized
        addSesameButtonView.exclamation.isHidden = false
        contentStackView.addArrangedSubview(addSesameButtonView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmDropKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop Key Hint
        let dropHintContiaoner = UIView(frame: .zero)
        let dropHintView = UILabel(frame: .zero)
        dropHintView.textColor = UIColor.placeHolderColor
        dropHintView.numberOfLines = 0 // 設置為0時，允許無限換行
        dropHintView.lineBreakMode = .byWordWrapping // 按單詞換行
        dropHintContiaoner.addSubview(dropHintView)
        dropHintView.autoPinLeading(constant: 10)
        dropHintView.autoPinTrailing(constant: -10)
        dropHintView.autoPinTop()
        dropHintView.autoPinBottom()
        
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [deviceModelName])
        dropHintView.text = String(format:"co.candyhouse.sesame2.dropKeyDesc".localized,
                                   arguments:[deviceModelName,deviceModelName, deviceModelName])
        
        contentStackView.addArrangedSubview(dropHintContiaoner)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
#if DEBUG
        // MARK: Reset Sesame
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.prepareConfirmResetKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif
    }
    
    func setupNFCCardView() {
        if mDevice is CHCardCapable {
            if let capable = mDevice as? CHCardCapable {
                let nfcCardView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                    navigationController?.pushViewController(NFCCardVC.instance(capable),animated: true)
                }
                nfcCardView.title = "co.candyhouse.sesame2.nfcCard".localized
                contentStackView.addArrangedSubview(nfcCardView)
                contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            }
        } else {
            L.d(tag,"don't support Card Capable !")
        }
    }
    
    func setupFingerView() {
        if mDevice is CHFingerPrintCapable {
            if let capable = mDevice as? CHFingerPrintCapable {
                let fingerView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                    navigationController?.pushViewController(FingerPrintListVC.instance(capable),animated: true)
                }
                fingerView.title = "co.candyhouse.sesame2.fingerprint".localized
                contentStackView.addArrangedSubview(fingerView)
                contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            }
        } else {
            L.d(tag,"don't support FingerPrint Capable !")
        }
    }
    
    func setupPassCodeView() {
        if mDevice is CHPassCodeCapable {
            if let capable = mDevice as? CHPassCodeCapable {
                let passcodeView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                    navigationController?.pushViewController(PassCodeVC.instance(capable),animated: true)
                }
                passcodeView.title = "co.candyhouse.sesame2.passcodes".localized
                contentStackView.addArrangedSubview(passcodeView)
                contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            }
        } else {
            L.d(tag,"don't support PassCode Capable !")
        }
    }
    
    func setupFaceView() {
        if mDevice is CHFaceCapable {
            if let capable = mDevice as? CHFaceCapable {
                let faceView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                    navigationController?.pushViewController(FaceListVC.instance(capable),animated: true)
                }
                faceView.title = "co.candyhouse.sesame2.faceView".localized
                contentStackView.addArrangedSubview(faceView)
                contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            }
        } else {
            L.d(tag,"don't support Face Capable !")
        }
    }
    
    func setupPamView() {
        if mDevice is CHPalmCapable {
            if let capable = mDevice as? CHPalmCapable {
                let palmView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                    navigationController?.pushViewController(PalmListVC.instance(capable),animated: true)
                }
                palmView.title = "co.candyhouse.sesame2.palmView".localized
                contentStackView.addArrangedSubview(palmView)
                contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            }
        } else {
            L.d(tag,"don't support Palm Capable !")
        }
    }
    
    func setRadarUI(tag: String, payload: Data){
        L.d("radar", payload.bytes)
        let sensitivityValue = Int(payload[1]) & 0xFF
        let distance = calculateDistanceFromFirmwareValue(firmwareValue: sensitivityValue)
        
        L.d("radar","来自\(tag)的雷达灵敏度值：\(sensitivityValue), 距离：\(distance)cm")
        
        executeOnMainThread {
            self.sliderView.slider.value = Float(distance)
            self.sliderView.updateBubble(withValue: self.formatDistanceText(distance))
            self.sliderView.isSliderHidden = false
        }
    }
    
    private func handleRadarSliderChange(slider: UISlider) {
        let distance = Int(slider.value)
        let sensitivityValue = calculateFirmwareValueFromDistance(distance: distance)
        
        self.sliderView.updateBubble(withValue: self.formatDistanceText(distance))
        
        L.d("radar","设置雷达灵敏度距离: \(distance)cm, 固件值: \(sensitivityValue)")
        
        setRadarSensitivity(device: self.mDevice, sensitivityValue: sensitivityValue)
    }
    
    // 根据固件值计算距离（使用线性插值）
    private func calculateDistanceFromFirmwareValue(firmwareValue: Int) -> Int {
        if firmwareValue >= 116 { return 30 }
        if firmwareValue <= 16 { return 270 }
        
        // 找到相邻的两个点进行插值
        for i in 0..<(DISTANCE_TO_FIRMWARE_TABLE.count - 1) {
            let point1 = DISTANCE_TO_FIRMWARE_TABLE[i]
            let point2 = DISTANCE_TO_FIRMWARE_TABLE[i + 1]
            
            if firmwareValue <= point1.firmware && firmwareValue >= point2.firmware {
                let ratio = Float(firmwareValue - point2.firmware) / Float(point1.firmware - point2.firmware)
                let distance = Float(point2.distance) + ratio * Float(point1.distance - point2.distance)
                return Int(distance)
            }
        }
        
        return 30
    }

    // 根据距离计算固件值（使用线性插值）
    private func calculateFirmwareValueFromDistance(distance: Int) -> UInt8 {
        if distance <= 30 { return 116 }
        if distance >= 270 { return 16 }
        
        // 找到相邻的两个点进行插值
        for i in 0..<(DISTANCE_TO_FIRMWARE_TABLE.count - 1) {
            let point1 = DISTANCE_TO_FIRMWARE_TABLE[i]
            let point2 = DISTANCE_TO_FIRMWARE_TABLE[i + 1]
            
            if distance >= point1.distance && distance <= point2.distance {
                let ratio = Float(distance - point1.distance) / Float(point2.distance - point1.distance)
                let firmwareValue = Float(point1.firmware) + ratio * Float(point2.firmware - point1.firmware)
                return UInt8(Int(firmwareValue))
            }
        }
        
        return 116
    }
    
    private func formatDistanceText(_ distance: Int) -> String {
        return "co.candyhouse.sesame2.face.distance".localized + " \(distance)cm"
    }
    
    private func setRadarSensitivity(device: CHSesameConnector, sensitivityValue: UInt8) {
        let payloadArray: [UInt8] = [0x33, sensitivityValue, 0, 0, 0]
        let payload = Data(payloadArray)
        
        device.setRadarSensitivity(payload: payload) { result in
            switch result {
            case .success:
                L.d("radar","雷达灵敏度设置成功")
            case .failure(let error):
                L.d("radar","雷达灵敏度设置失败: \(error)")
            }
        }
    }
    
    // MARK: QRCode Sharing View
    func presentQRCodeSharingView(sender: UIButton) {
        let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.ShareFriend".localized, preferredStyle: .actionSheet)
        //        L.d("mDevice.keyLevel => ",mDevice.keyLevel)
        if mDevice.keyLevel == 0 {
            let ownerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.ownerKey".localized, style: .default) { _ in
                executeOnMainThread {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.mDevice, keyLevel: KeyLevel.owner.rawValue) {
                        self.deviceMembersView?.getMembers()
                        
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(ownerKeyAction)
        }
        
        if (mDevice.keyLevel == 0 || mDevice.keyLevel == 1) {
            let managerKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.managerKey".localized, style: .default) { _ in
                executeOnMainThread {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.mDevice, keyLevel: KeyLevel.manager.rawValue)  {
                        self.deviceMembersView?.getMembers()
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }
            alertController.addAction(managerKeyAction)
        }
        
        let memberKeyAction = UIAlertAction(title: "co.candyhouse.sesame2.memberKey".localized, style: .default) { _ in
            executeOnMainThread {
                if self.mDevice.keyLevel == KeyLevel.guest.rawValue {
                    let qrCode = URL.qrCodeURLFromDevice(self.mDevice, deviceName: self.mDevice.deviceName, keyLevel: KeyLevel.guest.rawValue)
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.mDevice, qrCode: qrCode!)
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                } else {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.mDevice, keyLevel: KeyLevel.guest.rawValue) {
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
}

extension SesameBiometricDeviceSettingVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {1}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {mySesames.count}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let deviceModel = mySesames[indexPath.row]
        L.d("[添加設備列表]", deviceModel)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        cell.selectionStyle = .none
        cell.textLabel?.text = localDevices.filter { $0.deviceId.uuidString == deviceModel}.first?.deviceName ?? deviceModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let delete = UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized,
                                   style: .destructive) { (action) in
            let sesame2 = self.mySesames[indexPath.row]
            self.mDevice.removeSesame(tag: sesame2) { result in
                executeOnMainThread {
                    self.mySesames.removeAll { $0 == sesame2 }
                    self.sesame2ListView.reloadData()
                }
            }
            
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        // 同步Android，显示标题
        let deviceModel = mySesames[indexPath.row]
        let deviceName = localDevices.filter { $0.deviceId.uuidString == deviceModel }.first?.deviceName ?? deviceModel
        let alertController = UIAlertController(title: deviceName, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(delete)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }
}
