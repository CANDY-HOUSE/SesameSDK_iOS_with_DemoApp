//RegisterSesameDeviceViewController.swift

import UIKit
import SesameSDK

class RegisterSesameDeviceViewController: CHBaseViewController { //[joi todo]改為繼承CHBaseTableVC
    var registeredDevice: CHDevice?
    var dismissHandler: ((CHDevice?)->Void)?
    var tableViewProxy: CHTableViewProxy!
    private let statusViewHeight: CGFloat = 64
    private var statusViewTopInset: CGFloat = 0
    private var isBluetoothPoweredOff: Bool {
        CHBluetoothCenter.shared.scanning.bleStatus == .closed
    }
    
    private lazy var statusView: CHUIPlainSettingView = {
        let view = CHUIViewGenerator.plain()
        view.backgroundColor = .lockRed
        view.title = ""
        view.setColor(.white)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var emptyPlaceholderStr: NSAttributedString = {
        let fullAttributedString = NSMutableAttributedString(string: "")
        let firstString = "co.candyhouse.sesame2.NoBleDevices".localized
        let paragraphStyleCenter = NSMutableParagraphStyle()
        paragraphStyleCenter.alignment = .center
        paragraphStyleCenter.lineSpacing = 20
        let firstAtt = NSAttributedString(string: firstString, attributes: [.font: UIFont.systemFont(ofSize: UIFont.labelFontSize), .foregroundColor: UIColor.black, .paragraphStyle: paragraphStyleCenter])
        fullAttributedString.append(firstAtt)
        
        fullAttributedString.append(NSAttributedString(string: "\n"))
        let otherString = "co.candyhouse.sesame2.NoBleDevicesDetailDescription".localized
        let paragraphStyleLeft = NSMutableParagraphStyle()
        paragraphStyleLeft.alignment = .left
        paragraphStyleLeft.lineSpacing = 5
        let otherAtt = NSAttributedString(string: otherString, attributes: [.font: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize), .foregroundColor: UIColor.placeHolderColor, .paragraphStyle: paragraphStyleLeft])
        fullAttributedString.append(otherAtt)
        return fullAttributedString
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarBackgroundColor = .white
        CHBluetoothCenter.shared.delegate = self
        CHBluetoothCenter.shared.statusDelegate = self
        
        setClosableNavigationRightItem(#selector(dismissSelf))
        
        configureTable()
        
        setupRegisterStatusView()
        showRegisterBleStatusIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CHBluetoothCenter.shared.statusDelegate = self
        showRegisterBleStatusIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if CHBluetoothCenter.shared.statusDelegate === self {
            CHBluetoothCenter.shared.statusDelegate = nil
        }
    }
    
    override func didBecomeActive() {
        super.didBecomeActive()
        
        showRegisterBleStatusIfNeeded()
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [unowned self] it, _ in
            self.onCellItemPressed(it.rawValue as! CHDevice)
        } ,emptyPlaceholder: nil, richPlaceholder: emptyPlaceholderStr)
        tableViewProxy.configureTableHeader({}, nil)
        tableViewProxy.tableView.estimatedRowHeight = 120
        tableViewProxy.tableView.rowHeight = 120
    }
    
    private func setupRegisterStatusView() {
        view.addSubview(statusView)
        
        let heightConstraint = statusView.heightAnchor.constraint(equalToConstant: statusViewHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.bringSubviewToFront(statusView)
    }
    
    private func updateRegisterTableInsets() {
        guard let tableView = tableViewProxy?.tableView else {
            return
        }
        
        tableView.contentInset = UIEdgeInsets(
            top: statusViewTopInset,
            left: 0,
            bottom: 0,
            right: 0
        )
        
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    
    @discardableResult
    private func showRegisterBleStatusIfNeeded() -> Bool {
        let shouldShow = isBluetoothPoweredOff
        
        if shouldShow {
            statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
        }
        
        statusView.isHidden = !shouldShow
        statusViewTopInset = shouldShow ? statusViewHeight : 0
        
        updateRegisterTableInsets()
        
        view.bringSubviewToFront(statusView)
        view.layoutIfNeeded()
        
        return shouldShow
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    func onCellItemPressed(_ device: CHDevice) {
        ViewHelper.showLoadingInView(view: self.view)
        self.registeredDevice = device
        device.delegate = self
        if device.deviceStatus == .readyToRegister() {
            registerCHDevice(device)
        }
        if device.deviceStatus == .receivedBle() {
            device.connect() {_ in}
        }
    }
    
    private func registerCHDevice(_ device: CHDevice) {
        L.d("[註冊]0")
        device.register { [weak self] result in
            guard let self = self else { return }
            Sesame2Store.shared.deletePropertyFor(device)
            CHDeviceManager.shared.setHistoryTag()
            (device as? CHSesame2)?.configureLockPosition(lockTarget: 0, unlockTarget: 256) { _ in }
            device.setKeyLevel(KeyLevel.owner.rawValue)
            device.setDeviceName(device.deviceName)
            CHAPIClient.shared.putCHUserKey(CHUserKey.fromCHDevice(device).toData()) { _ in }
            executeOnMainThread {
                L.d("[註冊]2")
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = result {
                    L.d("[註冊]3")
                    self.view.makeToast(error.errorDescription())
                } else {
                    L.d("[註冊]4")
                    if let bot2 = device as? CHSesameBot2 {
                        Bot2InitHelper.clearBotScript(device: bot2) { _ in
                            bot2.getScriptNameList { result in
                                if case .success(_) = result {
                                    Bot2InitHelper.forceInitDefaults(device: bot2) { _ in }
                                }
                            }
                        }
                    }
                    self.dismissSelf()
                    self.dismissHandler?(self.registeredDevice)
                }
            }
        }
    }
}

extension RegisterSesameDeviceViewController: CHBleManagerDelegate {
    func didDiscoverUnRegisteredCHDevices(_ devices: [CHDevice]) {
        executeOnMainThread {
            self.showRegisterBleStatusIfNeeded()
            let customDiscriptors = devices.reduce(into: [String: CHDevice]()) { (result, device) in
                result[device.deviceId.uuidString] = result[device.deviceId.uuidString] ?? device
            }.map { $0.value }
                .sorted { $0.currentDistanceInCentimeter() < $1.currentDistanceInCentimeter() }
                .map { $0.convertToCellDescriptorModel(cellCls: RegisterSesameDeviceCell.self) }
            self.tableViewProxy.handleSuccessfulDataSource(nil, customDiscriptors)
            if let target = customDiscriptors.first?.rawValue as? CHDevice,
               case .receivedBle = target.deviceStatus {
                target.connect(result: {_ in })
            }
        }
    }
}

extension RegisterSesameDeviceViewController: CHDeviceStatusDelegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        if status == .readyToRegister() && self.registeredDevice?.deviceId == device.deviceId {
            device.delegate = nil
            registerCHDevice(device)
        }
    }
}

extension RegisterSesameDeviceViewController {
    static func instance(dismissHandler: ((CHDevice?)->Void)? = nil) -> RegisterSesameDeviceViewController {
        let registerSesame2ViewController = RegisterSesameDeviceViewController(nibName: nil, bundle: nil)
        registerSesame2ViewController.dismissHandler = dismissHandler
        UINavigationController().pushViewController(registerSesame2ViewController, animated: false)
        return registerSesame2ViewController
    }
}

extension RegisterSesameDeviceViewController: CHBleStatusDelegate {
    func didScanChange(status: CHScanStatus) {
        executeOnMainThread {
            self.showRegisterBleStatusIfNeeded()
        }
    }
}
