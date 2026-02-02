//
//  SesameTouchProSettingVC.swift
//  SesameUI
//  BleConnector Setting View
//  Created by JOi on 2023/7/24.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

extension BleConnectorSettingVC: DFUHelperDelegate {
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

class BleConnectorSettingVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate {
    var mDevice: CHSesameTouchPro!
    
    // MARK: getVersionTag
    private func getVersionTag() {
        mDevice.getVersionTag { result in
            switch result {
            case .success(let status):
                let fileName = DFUHelper.getDfuFileName(self.mDevice!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(_): break
//                L.d(error.errorDescription())
            }
        }
    }
    
    func onMechStatus(device: CHDevice) {
        executeOnMainThread { [self] in
            batteryView.value = "\(mDevice.mechStatus?.getBatteryPrecentage() ?? 0) %"
        }
    }
    
    func onSesame2KeysChanged(device: SesameSDK.CHSesameConnector, sesame2keys: [String : String]) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            mySesames = mDevice.sesame2Keys.keys.compactMap { $0 }
            self.showStatusViewIfNeeded()
            self.updateAddSesameButtonState()
        }
    }
    
    func onSlotFull(device: SesameSDK.CHSesameConnector) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.view.makeToast("co.candyhouse.sesame2.SlotFull".localized)
        }
    }
    
    func onSSMSupport(device: SesameSDK.CHSesameConnector, isSupport: Bool) {
        if !isSupport {
            executeOnMainThread { [weak self] in
                guard let self = self else { return }
                self.view.makeToast("co.candyhouse.sesame2.Unsupport".localized)
            }
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
            self.updateAddSesameButtonState()
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
    var statusView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var addSesameButtonView: CHUIPlainSettingView!
    var batteryView: CHUIArrowSettingView!
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var sesame2ListView = UITableView(frame: .zero)
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var dismissHandler: (()->Void)?

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

    deinit{
        mDevice.disconnect(){ _ in}
        self.deviceMemberWebView?.cleanup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let mDevice = mDevice else {print("mDevice is nil");return};        mDevice.delegate = self
        mySesames = mDevice.sesame2Keys.keys.compactMap { $0 }
        showStatusViewIfNeeded()

        if mDevice.deviceStatus == .receivedBle() {
            mDevice.connect() { _ in }
        }
        getVersionTag()
    }

    @objc func reloadFriends() {
        reloadMembers()
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

        contentStackView.addArrangedSubview(deviceMemberWebView(mDevice))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

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
        batteryView = deviceBatteryView(mDevice)
        contentStackView.addArrangedSubview(batteryView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = mDevice.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        // MARK: Add Sesame Hint
        let deviceName = mDevice.deviceName
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.bindSesameToBleConnector".localized, arguments: [
            deviceName
        ])
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

        // MARK: 连接设备(sesamelockers)列表
        contentStackView.addArrangedSubview(sesame2ListView)
        sesame2ListViewHeight = sesame2ListView.autoLayoutHeight(0)
        sesame2ListView.separatorColor = .lockGray
        
        // MARK: Add Sesame Buttom View
        addSesameButtonView = CHUIViewGenerator.plain { [unowned self] button,_ in
            let touchProKeysListVC = SesameBiometricDeviceKeysListVC.instance(device: self.mDevice)
            { device in
                self.navigationController?.popViewController(animated: true)
                self.mDevice.insertSesame(device) { _ in}
            }
            self.navigationController?.pushViewController(touchProKeysListVC, animated:true)
        }
        
        updateAddSesameButtonState()
        addSesameButtonView.title = "co.candyhouse.sesame2.addSesameToWM2".localized
        addSesameButtonView.exclamation.isHidden = false
        contentStackView.addArrangedSubview(addSesameButtonView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.dropKey(sender: sender as! UIButton)
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
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [deviceName])
        dropHintView.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: [deviceName, deviceName, deviceName])
        contentStackView.addArrangedSubview(dropHintContiaoner)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
    }
    
    // MARK: Trash Key
    func dropKey(sender: UIButton) {
        let title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [mDevice.deviceName])
        
        let trashKey = UIAlertAction(title: title,style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            CHAPIClient.shared.deleteCHUserKey(CHUserKey.fromCHDevice(self.mDevice).deviceUUIDData()) { deleteResult in
                if case .failure(let err) = deleteResult {
                    executeOnMainThread {
                        self.view.makeToast(err.errorDescription())
                        ViewHelper.hideLoadingView(view: self.view)
                    }
                } else {
                    Sesame2Store.shared.deletePropertyFor(self.mDevice)
                    self.mDevice.unregisterNotification()
                    self.mDevice.dropKey() { _ in
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.view)
//                                    self.isReset = true
                            self.navigationController?.popToRootViewController(animated: false)
                        }
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
    
    private func updateAddSesameButtonState() {
        let currentCount = self.mySesames.count
        
        addSesameButtonView.setColor(.darkText)
        
        // 有设备时隐藏感叹号
        addSesameButtonView.exclamation.isHidden = currentCount > 0
        
        // 没有设备时隐藏加号标签
        addSesameButtonView.hidePlusLable(currentCount == 0)
    }
}

extension BleConnectorSettingVC {
    static func instance(_ device: CHSesameTouchPro, dismissHandler: (()->Void)? = nil) -> BleConnectorSettingVC {
        let vc = BleConnectorSettingVC (nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.mDevice = device
        vc.dismissHandler = dismissHandler
        return vc
    }
}

extension BleConnectorSettingVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {1}

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {mySesames.count}

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let deviceModel = mySesames[indexPath.row]
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
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(delete)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }
}
