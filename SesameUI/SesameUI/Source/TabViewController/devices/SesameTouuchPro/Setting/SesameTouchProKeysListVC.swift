//
//  SesameTouchProKeysListVC.swift
//  SesameUI
//  若為open sensor 設定頁，不顯示ss5/ ss5 pro 以外的設備
//  Created by JOi Chao on 2023/6/16.
//  Copyright © 2023 CandyHouse. All rights reserved.

import Foundation
import SesameSDK
import UIKit

class SesameTouchProKeysListVC: UITableViewController {
    var mDevice: CHSesameTouchPro
    var selectionHandler: ((CHDevice)->Void)?
    
    init(device: CHSesameTouchPro, selectionHandler: @escaping (CHDevice)->Void) {
        self.mDevice = device
        self.selectionHandler = selectionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                if(self.mDevice.productModel == .openSensor || self.mDevice.productModel == .bleConnector){
                    chDevices = devices.data.filter { [.sesame5, .sesame5Pro].contains($0.productModel) }
                } else {
                    chDevices = devices.data.filter { [.sesame5, .sesame5Pro, .bikeLock2, .sesame4, .sesameBot, .bikeLock, .sesame2].contains($0.productModel) }
                }
            }
        }
        return chDevices
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
    
    static func instance(device: CHSesameTouchPro, selectionHandler: @escaping (CHDevice)->Void) -> SesameTouchProKeysListVC {
        let vc = SesameTouchProKeysListVC(device: device, selectionHandler: selectionHandler)
        return vc
    }
}
