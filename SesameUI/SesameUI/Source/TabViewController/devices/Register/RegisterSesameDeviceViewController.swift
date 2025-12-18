//RegisterSesameDeviceViewController.swift

import UIKit
import SesameSDK

class RegisterSesameDeviceViewController: CHBaseViewController { //[joi todo]改為繼承CHBaseTableVC
    var registeredDevice: CHDevice?
    var dismissHandler: ((CHDevice?)->Void)?
    var tableViewProxy: CHTableViewProxy!
    
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
//        L.d("[register]viewDidLoad =>",devices.count)
        navigationBarBackgroundColor = .white
        CHBluetoothCenter.shared.delegate = self
        setClosableNavigationRightItem(#selector(dismissSelf))
        configureTable()
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [unowned self] it, _ in
            self.onCellItemPressed(it.rawValue as! CHDevice)
        } ,emptyPlaceholder: nil, richPlaceholder: emptyPlaceholderStr)
        tableViewProxy.configureTableHeader({}, nil)
        tableViewProxy.tableView.estimatedRowHeight = 120
        tableViewProxy.tableView.rowHeight = 120
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
            CHUserAPIManager.shared.putCHUserKey(CHUserKey.fromCHDevice(device)) { _ in }
            executeOnMainThread {
                L.d("[註冊]2")
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = result {
                    L.d("[註冊]3")
                    self.view.makeToast(error.errorDescription())
                } else {
                    L.d("[註冊]4")
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
