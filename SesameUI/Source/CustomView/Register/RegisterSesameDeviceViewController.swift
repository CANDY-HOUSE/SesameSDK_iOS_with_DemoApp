//
//  RegisterSesameDeviceViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class RegisterSesameDeviceViewController: CHBaseTableViewController {
    enum Section {
        static let sesame2 = 0
        static let wifiModule2 = 1
        static let sesameBot = 2
        static let bikeLock = 3
    }

    // MARK: - Data model
    var devices: [CHDevice] = []
    var registerDeviceId: UUID?
    
    // MARK: - Flag
    private var registeredDevice: CHDevice?
    
    // MARK: - Callback
    var dismissHandler: ((CHDevice?)->Void)?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
        
        }
        
        CHBleManager.shared.delegate = self
        tableView.register(UINib(nibName: "RegisterSesameDeviceCell", bundle: nil),
                           forCellReuseIdentifier: "RegisterSesameDeviceCell")

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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(.white)
    }
    
    // MARK: - Methods
    func reloadTableView() {
        let isEmpty = devices.isEmpty
        noContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
        dismissHandler?(self.registeredDevice)
    }

    // MARK: - TableView DataSource Delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterSesameDeviceCell", for: indexPath) as! RegisterSesameDeviceCell
        cell.indexPath = indexPath
        var rssi = ""
        let device = devices[indexPath.row]
        if let currentDistanceInCentimeter = device.currentDistanceInCentimeter() {
            rssi = "\(currentDistanceInCentimeter) \("co.candyhouse.sesame2.cm".localized)"
        }
        cell.rssiLabel.text = rssi
        cell.sesame2DeviceIdLabel.text = device.deviceId.uuidString
        cell.sesame2StatusLabel.text = device.deviceStatusDescription()
        cell.rssiImageView.image = UIImage.SVGImage(named: "bluetooth",
                                                    fillColor: .sesame2Green)
        cell.deviceTypeLabel.text = device.deviceName
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ViewHelper.showLoadingInView(view: self.view)
        tableView.deselectRow(at: indexPath, animated: false)
        let device = devices[indexPath.row]
        switch device {
        case let sesame2 as CHSesame2:
            sesame2.delegate = self
            if sesame2.deviceStatus == .readyToRegister() {
                registerCHDevice(sesame2)
            } else {
                registerDeviceId = sesame2.deviceId
                sesame2.connect() {_ in}
            }
        case let wifiModule2 as CHWifiModule2:
            wifiModule2.delegate = self
            if wifiModule2.deviceStatus == .readyToRegister() {
                registerCHDevice(wifiModule2)
            } else {
                registerDeviceId = wifiModule2.deviceId
                wifiModule2.connect() {_ in}
            }
        case let sesameBot as CHSesameBot:
            sesameBot.delegate = self
            if sesameBot.deviceStatus == .readyToRegister() {
                registerCHDevice(sesameBot)
            } else {
                registerDeviceId = sesameBot.deviceId
                sesameBot.connect() { _ in }
            }
        case let bikeLock as CHSesameBike:
            bikeLock.delegate = self
            if bikeLock.deviceStatus == .readyToRegister() {
                registerCHDevice(bikeLock)
            } else {
                registerDeviceId = bikeLock.deviceId
                bikeLock.connect() { _ in }
            }
        default:
            break
        }
    }
    
    // MARK: Register Sesame2
    private func registerCHDevice(_ device: CHDevice) {
        device.register { result in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                } else {
                    
                    Sesame2Store.shared.deletePropertyFor(device)
                    let encodedHistoryTag = Sesame2Store.shared.getHistoryTag()
                    (device as? CHSesameLock)?.setHistoryTag(encodedHistoryTag) { _ in }
                    (device as? CHSesame2)?.configureLockPosition(lockTarget: 0, unlockTarget: 256) { _ in }
                    
                    if device is CHSesame2 {
                        device.setDeviceName("co.candyhouse.sesame2.Sesame".localized)
                    } else if device is CHSesameBot {
                        device.setDeviceName("co.candyhouse.sesame2.SesameBot".localized)
                    } else if device is CHSesameBike {
                        device.setDeviceName("co.candyhouse.sesame2.BikeLock".localized)
                    } else if device is CHWifiModule2 {
                        device.setDeviceName("co.candyhouse.sesame2.WifiModule2".localized)
                    }

                    self.devices.removeAll {
                        $0.deviceId == device.deviceId
                    }
                    executeOnMainThread {
                        self.reloadTableView()
                        self.registeredDevice = device
                        self.dismissSelf()
                    }
                }
            }
        }
    }
}

// MARK: - CHBleManagerDelegate
extension RegisterSesameDeviceViewController: CHBleManagerDelegate {
    func didDiscoverUnRegisteredCHDevices(_ devices: [CHDevice]) {
        executeOnMainThread {
            let sortedDevices = devices.sorted(by: {
                return $0.currentDistanceInCentimeter()! < $1.currentDistanceInCentimeter()!
            }).filter {
                $0.isRegistered == false
            }
            
//            guard (self.devices.map { $0.deviceId }) != (sortedDevices.map { $0.deviceId }) else {
//                return
//            }
            
            self.devices = sortedDevices
            
            if let sesame2 = self.devices.first as? CHSesame2 {
                if sesame2.deviceStatus == .receivedBle() {
                    sesame2.connect() { _ in }
                }
                sesame2.delegate = self
            } else if let sesameBot = self.devices.first as? CHSesameBot {
                if sesameBot.deviceStatus == .receivedBle() {
                    sesameBot.connect() { _ in }
                }
                sesameBot.delegate = self
            } else if let bikeLock = self.devices.first as? CHSesameBike {
                if bikeLock.deviceStatus == .receivedBle() {
                    bikeLock.connect() { _ in }
                }
                bikeLock.delegate = self
            } else if let wifiModule2 = self.devices.first as? CHWifiModule2 {
                if wifiModule2.deviceStatus == .receivedBle() {
                    wifiModule2.connect() { _ in }
                }
                wifiModule2.delegate = self
            }
            self.reloadTableView()
        }
    }
}

extension RegisterSesameDeviceViewController: CHSesame2StatusDelegate {
    func onBleDeviceStatusChanged(device: CHSesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if status == .readyToRegister() && registerDeviceId == device.deviceId {
            registerCHDevice(device)
        }
        
        executeOnMainThread {
            if let index = (self.devices.firstIndex {
                $0.deviceId == device.deviceId
            }), let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? RegisterSesameDeviceCell {
                cell.sesame2StatusLabel.text = device.deviceStatusDescription()
            }
        }
    }
}

// MARK: - CHSesame2Delegate
extension RegisterSesameDeviceViewController: CHSesame2Delegate, CHSesameBotDelegate, CHSesameBikeDelegate {
    
}

// MARK: - CHWifiModule2Delegate
extension RegisterSesameDeviceViewController: CHWifiModule2Delegate {
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHSesame2Status) {
        if status == .readyToRegister() && registerDeviceId == device.deviceId {
            registerCHDevice(device)
        }
        
        executeOnMainThread {
            if let index = (self.devices.firstIndex {
                $0.deviceId == device.deviceId
            }), let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? RegisterSesameDeviceCell {
                cell.sesame2StatusLabel.text = device.deviceStatusDescription()
            }
        }
    }
}

// MARK: - RegisterSesameDeviceCellDelegate
extension RegisterSesameDeviceViewController: RegisterSesameDeviceCellDelegate {
    func didLongPressed(_ cell: RegisterSesameDeviceCell) {
        dfuForCell(cell)
    }
    
    // MARK: dfuForCell
    func dfuForCell(_ cell: RegisterSesameDeviceCell) {
        
        var chooseDFUModeAlertController: UIAlertController?
        let indexPath = cell.indexPath!
        let device = devices[indexPath.row]
        if let sesame2 = device as? CHSesame2 {
            chooseDFUModeAlertController = UIAlertController(title: "",
                                                             message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                             preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: DFUHelper.sesame2ApplicationDfuFileName(sesame2),
                                              style: .default) { _ in
                executeOnMainThread {
                    let dfuAlertController = DFUAlertController.instanceWithSesame2(sesame2)
                    self.present(dfuAlertController, animated: true, completion: {
                        dfuAlertController.startDFU()
                    })
                }
            }
            chooseDFUModeAlertController!.addAction(confirmAction)
        } else if let _ = device as? CHWifiModule2 {
            
        } else if let switchDevice = device as? CHSesameBot {
            chooseDFUModeAlertController = UIAlertController(title: "",
                                                             message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                             preferredStyle: .actionSheet)
            
            let confirmAction = UIAlertAction(title: DFUHelper.sesameBotApplicationDfuFileName()!,
                                              style: .default) { _ in
                executeOnMainThread {
                    let dfuAlertController = DFUAlertController.instanceWithSwitch(switchDevice)
                    self.present(dfuAlertController, animated: true, completion: {
                        dfuAlertController.startDFU()
                    })
                }
            }
            chooseDFUModeAlertController!.addAction(confirmAction)
        } else if let bikeLock = device as? CHSesameBike {
            chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
            
            let confirmAction = UIAlertAction(title: DFUHelper.bikeLockApplicationDfuFileName()!,
                                              style: .default) { _ in
                executeOnMainThread {
                    let dfuAlertController = DFUAlertController.instanceWithBikeLock(bikeLock)
                    self.present(dfuAlertController, animated: true, completion: {
                        dfuAlertController.startDFU()
                    })
                }
            }
            chooseDFUModeAlertController!.addAction(confirmAction)
        }
        
        guard chooseDFUModeAlertController != nil else {
            return
        }

        chooseDFUModeAlertController!.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                                              style: .cancel,
                                                              handler: nil))
        if let popover = chooseDFUModeAlertController!.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(chooseDFUModeAlertController!, animated: true, completion: nil)
    }
}

// MARK: - Designated initializer
extension RegisterSesameDeviceViewController {
    static func instance(dismissHandler: ((CHDevice?)->Void)? = nil) -> RegisterSesameDeviceViewController {
        let registerSesame2ViewController = RegisterSesameDeviceViewController(nibName: nil, bundle: nil)
        registerSesame2ViewController.dismissHandler = dismissHandler
        let navigationController = UINavigationController()
        navigationController.pushViewController(registerSesame2ViewController, animated: false)
        return registerSesame2ViewController
    }
}
