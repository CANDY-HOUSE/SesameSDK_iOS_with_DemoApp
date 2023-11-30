//RegisterSesameDeviceViewController.swift

import UIKit
import SesameSDK

class RegisterSesameDeviceViewController: CHBaseTableViewController{ //should inherit CHBaseTableVC
    var devices: [CHDevice] = []
    var registeredDevice: CHDevice?
    var dismissHandler: ((CHDevice?)->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBarBackgroundColor = .white
        CHBluetoothCenter.shared.delegate = self
        tableView.register(UINib(nibName: "RegisterSesameDeviceCell", bundle: nil),forCellReuseIdentifier: "RegisterSesameDeviceCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
        tableView.separatorStyle = .none
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        noContentText = "co.candyhouse.sesame2.NoBleDevices".localized
        noContentDetailText = "co.candyhouse.sesame2.NoBleDevicesDetailDescription".localized
    }
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {devices.count}
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterSesameDeviceCell", for: indexPath) as! RegisterSesameDeviceCell
        cell.indexPath = indexPath
        let device = devices[indexPath.row]
        cell.rssiLabel.text = "\(device.currentDistanceInCentimeter()) \("co.candyhouse.sesame2.cm".localized)"
        cell.sesame2DeviceIdLabel.text = device.deviceId.uuidString
        cell.sesame2StatusLabel.text = device.deviceStatusDescription()
        cell.rssiImageView.image = UIImage.SVGImage(named: "bluetooth",fillColor: .sesame2Green)
        cell.deviceTypeLabel.text = device.deviceName
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ViewHelper.showLoadingInView(view: self.view)
        tableView.deselectRow(at: indexPath, animated: false)
        let device = devices[indexPath.row]
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
        device.register { result in
            Sesame2Store.shared.deletePropertyFor(device)
            let encodedHistoryTag = Sesame2Store.shared.getHistoryTag()
            (device as? CHSesameLock)?.setHistoryTag(encodedHistoryTag) { _ in }
            (device as? CHSesame2)?.configureLockPosition(lockTarget: 0, unlockTarget: 256) { _ in }
            device.setKeyLevel(KeyLevel.owner.rawValue)
            device.setDeviceName(device.deviceName)
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                } else {
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
            self.devices = devices
//                .filter{$0.rssi as! Int > -65}
                .sorted { $0.currentDistanceInCentimeter() < $1.currentDistanceInCentimeter() }
            if case .receivedBle = self.devices.first?.deviceStatus {
                self.devices.first?.connect(result: {_ in})
            }
            self.reloadTableView(isEmpty: self.devices.isEmpty)
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
