//
//  WifiSelectionTableViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class WifiSelectionTableViewController: UITableViewController {
    
    var wifis = [Wifi]()
    var wifiModule2: CHWifiModule2! {
        didSet {
            self.wifiModule2.delegate = self
            self.wifiModule2.connect { _ in
            }
        }
    }
    var dismissHandler: ((Wifi) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wifis.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WifiSelectionTableViewCell", for: indexPath) as! WifiSelectionTableViewCell
        let wifi = wifis[indexPath.row]
        cell.rssiLabel?.text = String(wifi.wifiInformation.rssi)
        cell.ssidLabel?.text = wifi.wifiInformation.ssidName()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wifi = wifis[indexPath.row]
        let ssid = wifi.wifiInformation.ssidName()
        
        let alertController = UIAlertController(title: ssid,
                                                message: "Please enter the wifi password",
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "WiFi password"
            textField.text = "Power0fDreams!"
            textField.isSecureTextEntry = false
        }
        
        let action = UIAlertAction(title: "OK", style: .default) { [weak alertController] _ in
            if let textField = alertController?.textFields?[0] {
                self.wifiModule2.disableWifiDiscovery { _ in

                }

                var wifi = self.wifis[indexPath.row]
                wifi.password = textField.text!

                self.dismiss(animated: true, completion: nil)
                self.dismissHandler?(wifi)
            }
            
        }
        alertController.addAction(action)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)!
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                                style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func passwordProvider() -> String {
        ""
    }
    
    
}

extension WifiSelectionTableViewController: CHWifiModule2Delegate {
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHWifiModule2Status) {
        if status == .readyToSetup {
            executeOnMainThread {
                ViewHelper.showLoadingInView(view: self.view)
            }
            device.enableWifiDiscovery { result in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                }
                switch result {
                case .success(let content):
                    let wifi = Wifi(id: UUID(),
                                    password: nil,
                                    wifiInformation: content.data)
                    let ssids = self.wifis.compactMap { wifi -> String? in
                        return wifi.wifiInformation.ssidName()
                    }
                    guard let ssidName = wifi.wifiInformation.ssidName() else {
                        return
                    }
                    if !ssids.contains(ssidName) {
                        self.wifis.append(wifi)
                        self.wifis.sort { left, right -> Bool in
                            left.wifiInformation.rssi > right.wifiInformation.rssi
                        }
                        executeOnMainThread {
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    L.d(error)
                }
            }
        }
    }
}
