//
//  RegisterWifiModule2ViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import CoreLocation

class RegisterWifiModule2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dismissButton: UIButton! {
        didSet {
            dismissButton.setTitle("", for: .normal)
            dismissButton.setImage( UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        }
    }

    var wifiModule2s: [CHWifiModule2] = []
    var selectedIndex: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        CHBleManager.shared.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for wifiModule2 in wifiModule2s {
            wifiModule2.disconnect { _ in
                
            }
        }
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        wifiModule2s.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterWifiModule2Cell", for: indexPath) as! RegisterWifiModule2Cell
        let wifiModule2 = wifiModule2s[indexPath.row]
        cell.wifiModule2 = wifiModule2
        cell.refreshUI()
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        let wifiModule2 = wifiModule2s[indexPath.row]
        let wifiSelectionTableViewController = UIStoryboard.viewControllers.wifiSelectionTableViewController!
        wifiSelectionTableViewController.wifiModule2 = wifiModule2
        wifiSelectionTableViewController.dismissHandler = { wifi in
            self.registerWifiModule2WithWifi(wifi)
        }
        present(wifiSelectionTableViewController, animated: true, completion: nil)
    }
    
    // MARK: - Register WifiModule2
    func registerWifiModule2WithWifi(_ wifi: Wifi) {
        guard selectedIndex != nil else {
            return
        }
        let wifiModule2 = wifiModule2s[selectedIndex!]
        ViewHelper.showLoadingInView(view: view)
        
        wifiModule2.delegate = self
        wifiModule2.connect(result: { _ in
            self.registerWifiModule2(wifiModule2, wifi: wifi)
        })
    }
    
    func registerWifiModule2(_ wifiModule2: CHWifiModule2, wifi: Wifi) {
        wifiModule2.register { result in
            switch result {
            case .success(_):
                self.setupWifiCredential(wifiModule2: wifiModule2, wifi: wifi)
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
        
    func setupWifiCredential(wifiModule2: CHWifiModule2, wifi: Wifi) {
        wifiModule2.sendWifiCredential(ssid: wifi.wifiInformation.ssidName()!,
                                       password: wifi.password!) { result in
                                        switch result {
                                        case .success(_):
    //                WM2 connected to AP, waiting WM2 connect to AWSIoT
                                            break
                                        case .failure(let error):
                                            self.view.makeToast(error.errorDescription())
                                        }
        }
    }
}

extension RegisterWifiModule2ViewController: CHWifiModule2Delegate {
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHWifiModule2Status) {
        if status == .connected {
            updateSesame2ToWifiModule2Shadow(device)
        }
    }
    
    func updateSesame2ToWifiModule2Shadow(_ device: CHWifiModule2) {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                device.updateSesame2s(sesame2s.data) { result in
                    switch result {
                    case .success(_):
                        for wifiModule2 in self.wifiModule2s {
                            wifiModule2.disconnect { _ in
                                
                            }
                        }
                        executeOnMainThread {
                            self.dismiss(animated: true, completion: nil)
                        }
                    case .failure(let error):
                        self.view.makeToast(error.errorDescription())
                    }
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
}

extension RegisterWifiModule2ViewController: CHBleManagerDelegate {

    public func didDiscoverUnRegisteredWifiModule2s(_ wifiModule2s: [CHWifiModule2]) {
        self.wifiModule2s = wifiModule2s.sorted(by: {
            return $0.rssi!.intValue > $1.rssi!.intValue
        })
        executeOnMainThread {
            self.tableView.reloadData()
        }
    }
}
