//
//  WifiModule2SSIDScanViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/08.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

@objc protocol WifiModule2SSIDScanViewControllerDelegate: class {
    func onSSIDSelected(_ ssid: String)
    @objc func onScanRequested()
}

class WifiModule2SSIDScanViewController: CHBaseTableViewController {
    
    var ssids = [SSID]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var noContentRefreshControl: UIRefreshControl = UIRefreshControl()
    weak var delegate: WifiModule2SSIDScanViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "WifiModule2SSIDScanCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(scanSSID), for: .valueChanged)
        tableView.refreshControl = refreshControl
        noContentRefreshControl.addTarget(self, action: #selector(scanSSID), for: .valueChanged)
        noContentView.refreshControl = noContentRefreshControl
        noContentView.isScrollEnabled = true
        
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        
        noContentText = "co.candyhouse.sesame2.PullToRefresh".localized
        tableView.tableFooterView = UIView()
        
        scanSSID()
        title = "co.candyhouse.sesame2.selectSSID".localized
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)    
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            navigationController?.navigationBar.barTintColor = .white
        }
    }
    
    @objc func scanSSID() {
        delegate?.onScanRequested()
        refreshControl.endRefreshing()
        noContentRefreshControl.endRefreshing()
    }
    
    func reloadTableView() {
        let isEmpty = ssids.isEmpty
        noContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ssids.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WifiModule2SSIDScanCell
        let wifiSignal: String
        let rssiStrength = ssids[indexPath.row].rssi + 100
        if rssiStrength >= 50 {
            wifiSignal = "wifi_strong"
        } else if rssiStrength >= 30 && rssiStrength < 50 {
            wifiSignal = "wifi_middle"
        } else {
            wifiSignal = "wifi_weak"
        }
        cell.iconView.image = UIImage.CHUIImage(named: wifiSignal)
        cell.ssidLabel.text = ssids[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.onSSIDSelected(ssids[indexPath.row].name)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        40
    }
}

extension WifiModule2SSIDScanViewController {
    static func instance() -> WifiModule2SSIDScanViewController {
        let wifiModule2SSIDScanViewController = WifiModule2SSIDScanViewController(nibName: nil, bundle: nil)
        _ = UINavigationController(rootViewController: wifiModule2SSIDScanViewController)
        return wifiModule2SSIDScanViewController
    }
}
