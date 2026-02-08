//
//  SesameBiometricDeviceKeysListVC.swift
//  SesameUI
//  若為open sensor 設定頁，不顯示ss5/ ss5 pro 以外的設備
//  Created by JOi Chao on 2023/6/16.
//  Copyright © 2023 CandyHouse. All rights reserved.

import Foundation
import SesameSDK
import UIKit

class SesameBiometricDeviceKeysListVC: UITableViewController {
    var mDevice: CHSesameBasePro
    var selectionHandler: ((CHDevice)->Void)?
    
    init(device: CHSesameBasePro, selectionHandler: @escaping (CHDevice)->Void) {
        self.mDevice = device
        self.selectionHandler = selectionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        let allLocks: [CHProductModel] = [
            .sesame2,
            .sesame4,
            .bikeLock,
            .bikeLock2,
            .bikeLock3,
            .sesame5,
            .sesame5Pro,
            .sesame5US,
            .sesameBot,
            .sesameBot2,
            .bleConnector,
            .sesame6Pro,
            .sesameMiwa
        ]
        
        CHDeviceManager.shared.getCHDevices { [self] result in
            if case let .success(devices) = result {
                var allowedProducts: [CHProductModel]
                
                if mDevice.productModel == .openSensor || mDevice.productModel == .openSensor2 {
                    let sesame2KeyDevices = devices.data.filter { device in
                        mDevice.sesame2Keys.keys.contains(device.deviceId.uuidString)
                    }
                    
                    let hasLockInSesame2Keys = sesame2KeyDevices.contains { allLocks.contains($0.productModel) }
                    let hasHub3InSesame2Keys = sesame2KeyDevices.contains { $0.productModel == .hub3 }
                    
                    if hasLockInSesame2Keys {
                        allowedProducts = allLocks
                    } else if hasHub3InSesame2Keys {
                        allowedProducts = [.hub3]
                    } else {
                        allowedProducts = [.hub3] + allLocks
                    }
                } else {
                    allowedProducts = allLocks
                }
                
                chDevices = devices.data.filter { allowedProducts.contains($0.productModel) }
            }
        }
        return chDevices
            .filter { !mDevice.sesame2Keys.keys.contains($0.deviceId.uuidString) }
            .filter { $0.keyLevel < KeyLevel.guest.rawValue }
            .sorted { left, right -> Bool in
                left.compare(right)
            }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { keys.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = keys[indexPath.row].deviceName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectionHandler?(keys[indexPath.row])
    }
    
    static func instance(device: CHSesameBasePro, selectionHandler: @escaping (CHDevice)->Void) -> SesameBiometricDeviceKeysListVC {
        let vc = SesameBiometricDeviceKeysListVC(device: device, selectionHandler: selectionHandler)
        return vc
    }
}
