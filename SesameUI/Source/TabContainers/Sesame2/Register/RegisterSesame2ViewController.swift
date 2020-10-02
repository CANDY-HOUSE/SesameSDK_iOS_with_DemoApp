//
//  RegisterSesame2ViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class RegisterSesame2ViewController: CHBaseTableViewController {

    // MARK: - Data model
    var unregisteredSesame2s = [CHSesame2]() {
        didSet {
            unregisteredSesame2s.first?.connect() { _ in
                
            }
        }
    }
    
    // MARK: - Flag
    private var isRegisteredNewSesame2 = false
    
    // MARK: - Callback
    var dismissHandler: ((Bool)->Void)?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }
        
        CHBleManager.shared.delegate = self
        tableView.register(UINib(nibName: "RegisterSesame2Cell", bundle: nil),
                           forCellReuseIdentifier: "RegisterSesame2Cell")

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
        tableView.separatorStyle = .none

        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage( UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = dismissButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(.white)
    }
    
    // MARK: - Methods
    func reloadTableView() {
        let isEmpty = unregisteredSesame2s.isEmpty
        notContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
        dismissHandler?(self.isRegisteredNewSesame2)
    }

    // MARK: - TableView DataSource Delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return unregisteredSesame2s.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterSesame2Cell", for: indexPath) as! RegisterSesame2Cell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: RegisterSesame2Cell, atIndexPath indexPath: IndexPath) {
        let unregisteredSesame2 = unregisteredSesame2s[indexPath.row]
        var rssi = ""
        if let currentDistanceInCentimeter = unregisteredSesame2.currentDistanceInCentimeter() {
            rssi = "\(currentDistanceInCentimeter) \("co.candyhouse.sesame-sdk-test-app.cm".localized)"
        }
        cell.rssiLabel.text = rssi
        cell.rssiImageView.image = UIImage.SVGImage(named: "bluetooth",
                                                    fillColor: .sesame2Green)
        cell.sesame2DeviceIdLabel.text = unregisteredSesame2.deviceId.uuidString
        cell.sesame2StatusLabel.text = CHConfiguration.shared.isDebugModeEnabled() ? unregisteredSesame2.deviceStatus.description() : ""
        cell.delegate = self
        cell.indexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let unregisteredSesame2 = unregisteredSesame2s[indexPath.row]
        unregisteredSesame2.delegate = self
        if unregisteredSesame2.deviceStatus == .readyToRegister {
            registerSesame2(unregisteredSesame2)
        } else {
            unregisteredSesame2.connect(){_ in}
        }
    }
    
    // MARK: Register Sesame2
    private func registerSesame2(_ sesame2: CHSesame2) {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.view)
        }
        sesame2.registerSesame2( { result in
            switch result {

            case .success(_):
                
                L.d("註冊成功", "configureLockPosition")
                
                Sesame2Store.shared.deletePropertyAndHisotryForDevice(sesame2)
                
                let mySesameText = "ドラえもん".localized
                guard let encodedHistoryTag = mySesameText.data(using: .utf8) else {
                    assertionFailure("Encode historyTag failed")
                    return
                }
                
                L.d("註冊成功", "setHistoryTag", mySesameText)
                
                sesame2.setHistoryTag(encodedHistoryTag) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                
                sesame2.configureLockPosition(lockTarget: 0, unlockTarget: 256){ result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.isRegisteredNewSesame2 = true
                    self.dismissSelf()
                }
                
            case .failure(_):
                break
            }
        })
    }
}

// MARK: - CHBleManagerDelegate
extension RegisterSesame2ViewController: CHBleManagerDelegate {
    func didDiscoverUnRegisteredSesame2s(sesame2s: [CHSesame2]) {
        self.unregisteredSesame2s = sesame2s.sorted(by: {
            return $0.rssi!.intValue > $1.rssi!.intValue
        })
        executeOnMainThread {
            self.reloadTableView()
        }
    }
}

// MARK: - CHSesame2Delegate
extension RegisterSesame2ViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        
        if status == .readyToRegister {
            registerSesame2(device)
        }
    }
}

// MARK: - RegisterSesame2CellDelegate
extension RegisterSesame2ViewController: RegisterSesame2CellDelegate {
    func registerSesame2Cell(_ cell: RegisterSesame2Cell, didLongPressedAtIndexPath indexPath: IndexPath) {
        dfuForCell(cell, atIndexPath: indexPath)
    }
    
    // MARK: dfuForCell
    func dfuForCell(_ cell: RegisterSesame2Cell, atIndexPath indexPath: IndexPath) {
        
        let chooseDFUModeAlertController = UIAlertController(title: "",
                                                             message: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                             preferredStyle: .actionSheet)
        
        let confirmAction = UIAlertAction(title: DFUHelper.applicationDfuFileName()!,
                                          style: .default) { _ in
            let sesame2 = self.unregisteredSesame2s[indexPath.row]
            executeOnMainThread {
                let dfuAlertController = DFUAlertController.instanceWithSesame2(sesame2)
                self.present(dfuAlertController, animated: true, completion: {
                    dfuAlertController.startDFU()
                })
            }
        }
        chooseDFUModeAlertController.addAction(confirmAction)
        chooseDFUModeAlertController.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                                             style: .cancel,
                                                             handler: nil))
        if let popover = chooseDFUModeAlertController.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(chooseDFUModeAlertController, animated: true, completion: nil)
    }
}

// MARK: - Designated initializer
extension RegisterSesame2ViewController {
    static func instance(dismissHandler: ((Bool)->Void)? = nil) -> RegisterSesame2ViewController {
        let registerSesame2ViewController = RegisterSesame2ViewController(nibName: nil, bundle: nil)
        registerSesame2ViewController.dismissHandler = dismissHandler
        let navigationController = UINavigationController()
        navigationController.pushViewController(registerSesame2ViewController, animated: false)
        return registerSesame2ViewController
    }
}
