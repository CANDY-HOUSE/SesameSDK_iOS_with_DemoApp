//
//  WifiModule2KeysListViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class WifiModule2KeysListViewController: UITableViewController {
    
    var selectionHandler: ((CHDevice)->Void)?
    
    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data.filter { [
                    .sesame5,
                    .sesame5Pro,
                    .sesame4,
                    .sesameBot,
                    .bikeLock,
                    .sesame2,
                    .sesame5US,
                    .sesameMiwa].contains($0.productModel) }
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
    
    static func instance(_ selectionHandler: @escaping (CHDevice)->Void) -> WifiModule2KeysListViewController {
        let vc = WifiModule2KeysListViewController(nibName: nil, bundle: nil)
        vc.selectionHandler = selectionHandler
        return vc
    }
}
