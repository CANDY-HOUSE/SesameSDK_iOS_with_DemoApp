//
//  OpenSensorSettingVC.swift
//  SesameUI
//
//  Created by Joi Chao on 2023/7/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import AWSMobileClientXCF
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

class OpenSensorSettingVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate, DeviceControllerHolder, CHRemoteNanoDelegate {

    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!
    
    var mDevice: CHSesameTouchPro! {
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
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(_): break
//                L.d(error.errorDescription())
            }
        }
    }
    
    func onSesame2KeysChanged(device: SesameSDK.CHSesameConnector, sesame2keys: [String : String]) {
        //        L.d("[Tpro][onSesame2KeysChanged!!][sesame2Keys]",mDevice.sesame2Keys.keys)
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

    func onTriggerDelaySecondReceived(device: CHSesameConnector, setting: CHRemoteBaseTriggerSettings) {
        self.opsUInt = setting.triggerDelaySecond
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
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var statusView: CHUIPlainSettingView!
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var dfuView: CHUIPlainSettingView!
    var opsLockView: CHUIExpandableSettingView!
    var sesame2ListView = UITableView(frame: .zero)
    var addSesameButtonView: CHUIPlainSettingView!
    var changeNameView: CHUIPlainSettingView!
    var dismissHandler: (()->Void)?
    
    var opsUInt: UInt8 = 0 {
        didSet{
            executeOnMainThread { [self] in
                let arg = "\(String(format: "%.1f", Double(opsUInt) * 0.3))" + "co.candyhouse.sesame2.sec".localized
                let opsText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [arg])
                self.opsLockView?.value = opsText
                self.opsLockView?.pickerView.selectRow(times.firstIndex(of: Int(opsUInt))!, inComponent: 0, animated: false)
            }
        }
    }

    override func viewDidLoad() {
//        L.d("[op sensor] viewDidLoad!!")
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

    deinit{ mDevice.disconnect(){ _ in} }

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
        self.opsUInt = mDevice.triggerDelaySetting?.triggerDelaySecond ?? 0
    }

    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        // MARK: top status
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)

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
        
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        modelView.tag = kTagModelView
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        // MARK: Permission
        let permissionView = CHUIViewGenerator.plain()
        permissionView.title = "co.candyhouse.sesame2.Permission".localized
        permissionView.value = KeyLevel(rawValue: mDevice.keyLevel)!.description()
        contentStackView.addArrangedSubview(permissionView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: 长按触发按钮
        if mDevice.productModel == .remoteNano {
            opsLockView = CHUIViewGenerator.expandable(){ sender,_ in }
            opsLockView.title = "remoteNanoTriggerSettingHint".localized
            opsLockView.pickerView.delegate = self
            opsLockView.pickerView.dataSource = self
            opsLockView.pickerView.tag = 2
            opsLockView.fold()
            contentStackView.addArrangedSubview(opsLockView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        // MARK: OTA - DFU View
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
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
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = mDevice.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        // MARK: 下面接钥匙管理
        // MARK: Add Sesame Hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
       
        titleLabel.text = String(format: "co.candyhouse.sesame2.bindSesame2ToSensor".localized, arguments: [modelView.value])
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
                self.mDevice.insertSesame(device) { _ in
                    L.d("[tpo][addSesameButtonView][insertSesame]添加成功？",device.deviceName)
                }
            }
            self.navigationController?.pushViewController(touchProKeysListVC, animated:true)
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
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [modelView.value])
        contentStackView.addArrangedSubview(dropKeyView)
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
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                                       style: .destructive) { _ in
            self.resetSesame5()
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                  style: .cancel) { (action) in }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(unregister)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    func resetSesame5() {
        ViewHelper.showLoadingInView(view: view)
        if AWSMobileClient.default().currentUserState == .signedIn {
            CHUserAPIManager.shared.getSubId { subId in
                guard let subId = subId else {
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                    }
                    return
                }
                var userKey = CHUserKey.fromCHDevice(self.mDevice)
                userKey.subUUID = subId
                CHUserAPIManager.shared.deleteCHUserKey(userKey) { deleteResult in
                    if case .failure(_) = deleteResult {
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.view)
                        }
                    } else {
                        Sesame2Store.shared.deletePropertyFor(self.mDevice)
                        self.mDevice.unregisterNotification()
                        self.mDevice.reset { resetResult in
                            executeOnMainThread {
                                ViewHelper.hideLoadingView(view: self.view)
//                                self.isReset = true
                                self.navigationController?.popToRootViewController(animated: false)
                            }
                        }
                    }
                }
            }
        } else {
            Sesame2Store.shared.deletePropertyFor(self.mDevice)
            self.mDevice.unregisterNotification()
            self.mDevice.reset { resetResult in
                executeOnMainThread {
                    //self.isReset = true
                    ViewHelper.hideLoadingView(view: self.view)
                    self.navigationController?.popToRootViewController(animated: false)
                }
            }
        }
    }
    
    // MARK: Trash Key
    func dropKey(sender: UIButton) {
        let modelView = contentStackView.viewWithTag(kTagModelView) as! CHUIPlainSettingView
        var title: String
        title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [modelView.value])
        
        let trashKey = UIAlertAction(title: title,style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            if AWSMobileClient.default().currentUserState == .signedIn {
                CHUserAPIManager.shared.getSubId { subId in
                    guard let subId = subId else {
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.view)
                        }
                        return
                    }
                    var userKey = CHUserKey.fromCHDevice(self.mDevice)
                    userKey.subUUID = subId
                    CHUserAPIManager.shared.deleteCHUserKey(userKey) { deleteResult in
                        if case .failure(_) = deleteResult {
                            executeOnMainThread {
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
            } else {
                Sesame2Store.shared.deletePropertyFor(self.mDevice)
                self.mDevice.unregisterNotification()
                self.mDevice.dropKey() { _ in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
//                        self.isReset = true
                        self.navigationController?.popToRootViewController(animated: false)
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
}

extension OpenSensorSettingVC: DFUHelperDelegate {
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

extension OpenSensorSettingVC {
    static func instance(_ device: CHSesameTouchPro, dismissHandler: (()->Void)? = nil) -> OpenSensorSettingVC {
        let vc = OpenSensorSettingVC(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.mDevice = device
        vc.dismissHandler = dismissHandler
        return vc
    }
}

extension OpenSensorSettingVC: UITableViewDataSource, UITableViewDelegate {

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
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(delete)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }
}

private let times = Array([0, 10])
extension OpenSensorSettingVC: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    // MARK: Picker View DataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { times.count }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        if (pickerLabel == nil) {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = "\(String(format: "%.1f", Double(times[row]) * 0.3))" + "co.candyhouse.sesame2.sec".localized
        return pickerLabel!
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        opsPickerDidSelectRow(row)
        opsLockView.isPickerOn = false
    }
    
    private func opsPickerDidSelectRow(_ row: Int) {
        let val = times[row]
        mDevice.setTriggerDelayTime(UInt8(val)) { res in
            if case .failure(let err) = res {
                executeOnMainThread {
                    self.view.makeToast(err.errorDescription())
                }
            }
        }
    }
}
