//
//  SesameTouchProSettingVC.swift
//  SesameUI
//  Touch + Touch Pro Setting View
//  Created by tse on 2023/5/16.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

extension SesameTouchProSettingVC: DFUHelperDelegate {
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

extension SesameTouchProSettingVC {
    static func instance(_ device: CHSesameTouchPro, dismissHandler: (()->Void)? = nil) -> SesameTouchProSettingVC {
        let vc = SesameTouchProSettingVC(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.mDevice = device
        vc.dismissHandler = dismissHandler
        return vc
    }
}

class SesameTouchProSettingVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate {
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
    
    func onSesame2KeysChanged(device: SesameSDK.CHSesameConnector, sesame2keys: [String : String]) {
        mySesames = mDevice.sesame2Keys.keys.compactMap { $0 }
        self.showStatusViewIfNeeded()
        executeOnMainThread { [self] in
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
        DispatchQueue.main.async {
            if CHBluetoothCenter.shared.scanning == .bleClose() {
                self.statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
                self.statusView.isHidden = false
            } else if self.mDevice.deviceStatus.loginStatus == .unlogined {
                self.statusView.isHidden = false
                self.statusView.title = self.mDevice.localizedDescription()
            } else {
                self.statusView.isHidden = true
            }
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
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var addSesameButtonView: CHUIPlainSettingView!
    let batteryView = CHUIViewGenerator.plain ()
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
        
        // MARK: Top status
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            ChangeValueDialog.show(mDevice.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
                self.mDevice.setDeviceName(name)
                self.changeNameView.value = name
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    listViewController.reloadTableView()
                }
            }
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = mDevice.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        
        // MARK: Device model
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        
        // MARK: NfcCards
        let nfcCardView = CHUIViewGenerator.arrow { [unowned self] _,_ in
            navigationController?.pushViewController(NFCCardVC.instance(mDevice),animated: true)
        }
        nfcCardView.title = "co.candyhouse.sesame2.nfcCard".localized
        contentStackView.addArrangedSubview(nfcCardView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            
        // MARK: fingers
        let fingerView = CHUIViewGenerator.arrow { [unowned self] _,_ in
            navigationController?.pushViewController(FingerPrintListVC.instance(mDevice),animated: true)
        }
        fingerView.title = "co.candyhouse.sesame2.fingerprint".localized
        contentStackView.addArrangedSubview(fingerView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
            
        if (mDevice.productModel == .sesameTouchPro){
            // MARK: PassCode
            let passcodeView = CHUIViewGenerator.arrow { [unowned self] _,_ in
                navigationController?.pushViewController(PassCodeVC.instance(mDevice),animated: true)
            }
            passcodeView.title = "co.candyhouse.sesame2.passcodes".localized
            contentStackView.addArrangedSubview(passcodeView)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",message: "co.candyhouse.sesame2.SesameOSUpdate".localized, preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: DFUHelper.getDfuFileName(self.mDevice),
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
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))


        // MARK: Add Sesame Hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = "co.candyhouse.sesame2.bindSesame2ToTouch".localized
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
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
            let touchProKeysListVC = SesameTouchProKeysListVC.instance(device: self.mDevice)
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
            self.dropKey(sender: sender as! UIButton)
        }
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        
        // MARK: Drop Key Hint
        let dropHintContiaoner = UIView(frame: .zero)
        let dropHintView = UILabel(frame: .zero)
        dropHintView.textColor = UIColor.placeHolderColor
        dropHintView.numberOfLines = 0
        dropHintView.lineBreakMode = .byWordWrapping
        dropHintContiaoner.addSubview(dropHintView)
        dropHintView.autoPinLeading(constant: 10)
        dropHintView.autoPinTrailing(constant: -10)
        dropHintView.autoPinTop()
        dropHintView.autoPinBottom()
        
        if(mDevice.productModel == .sesameTouch){
            dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: ["co.candyhouse.sesame2.SSMTouch".localized])
            dropHintView.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.SSMTouch".localized, "co.candyhouse.sesame2.SSMTouch".localized, "co.candyhouse.sesame2.SSMTouch".localized])
        }else{
            let deviceName = "co.candyhouse.sesame2.SSMTouchPro".localized
            dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [deviceName])
            dropHintView.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: [deviceName, deviceName, deviceName])
        }
        
        contentStackView.addArrangedSubview(dropHintContiaoner)
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
            Sesame2Store.shared.deletePropertyFor(self.mDevice)
            self.mDevice.unregisterNotification()
            self.mDevice.reset { resetResult in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.navigationController?.popToRootViewController(animated: false)
                }
            }
    }
    
    
    // MARK: Trash Key
    func dropKey(sender: UIButton) {
        var title: String
        if (mDevice.productModel == .sesameTouch) {
            title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: ["co.candyhouse.sesame2.SSMTouch".localized])
        } else {
            title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: ["co.candyhouse.sesame2.SSMTouchPro".localized])
        }
        
        let trashKey = UIAlertAction(title: title,style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
                Sesame2Store.shared.deletePropertyFor(self.mDevice)
                self.mDevice.unregisterNotification()
                self.mDevice.dropKey() { _ in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.navigationController?.popToRootViewController(animated: false)
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

extension SesameTouchProSettingVC: UITableViewDataSource, UITableViewDelegate {

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

