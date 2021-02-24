//
//  SesameDeviceListViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class SesameDeviceListViewController: CHBaseTableViewController {
    // MARK: - Cell controllers
    var devices: [CHDevice] = []
    
    // MARK: - UI components
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = UIApplication.shared.statusBarFrame.height + 25
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var noContentRefreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
        tableView.separatorStyle = .none
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(pullDown), for: .valueChanged)
        noContentRefreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        noContentRefreshControl.addTarget(self, action: #selector(pullDown), for: .valueChanged)
        tableView.refreshControl = refreshControl
        noContentView.refreshControl = noContentRefreshControl
        noContentView.isScrollEnabled = true
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        tableView.register(UINib(nibName: "Sesame2ListCell", bundle: nil),
                           forCellReuseIdentifier: "Sesame2ListCell")
        tableView.register(UINib(nibName: "SesameBotListCell", bundle: nil),
                           forCellReuseIdentifier: "SesameBotListCell")
        tableView.register(UINib(nibName: "BikeLockListCell", bundle: nil),
                           forCellReuseIdentifier: "BikeLockListCell")
        tableView.register(UINib(nibName: "WifiModule2ListCell", bundle: nil),
                           forCellReuseIdentifier: "WifiModule2ListCell")
        
        getKeysFromCache()
        
        noContentText = "co.candyhouse.sesame2.NoDevices".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
            executeOnMainThread {
                self.refreshControl.beginRefreshing()
                let offsetPoint = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
                self.tableView.setContentOffset(offsetPoint, animated: true)
            }
        }
        if noContentRefreshControl.isRefreshing {
            noContentRefreshControl.endRefreshing()
            executeOnMainThread {
                self.noContentRefreshControl.beginRefreshing()
                let offsetPoint = CGPoint.init(x: 0, y: -self.noContentRefreshControl.frame.size.height)
                self.noContentView.setContentOffset(offsetPoint, animated: true)
            }
        }
        tabBarController?.tabBar.barTintColor = .white
    }
    
    override func didBecomeActive() {
        super.didBecomeActive()
        getKeysFromCache()
    }
    
    @objc func pullDown() {
        WatchKitFileTransfer.shared.transferKeysToWatch()
        getKeysFromCache()
    }
    
    func getKeysFromCache() {
        CHDeviceManager.shared.getCHDevices { getResult in
            switch getResult {
            case .success(let devices):
                self.devices = devices.data.sorted { left, right -> Bool in
                    left.compare(right)
                }
                executeOnMainThread {
                    self.refreshControl.endRefreshing()
                    self.noContentRefreshControl.endRefreshing()
                    self.reloadTableView()
                }
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
    
    // MARK: reloadTableView
    func reloadTableView() {
        let isEmpty = devices.isEmpty
        noContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let device = devices[indexPath.row]
        
        if let sesame2 = device as? CHSesame2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Sesame2ListCell", for: indexPath)
            let sesame2Cell = cell as! Sesame2ListCell
            sesame2Cell.sesame2 = sesame2
        } else if let sesameBot = device as? CHSesameBot {
            cell = tableView.dequeueReusableCell(withIdentifier: "SesameBotListCell", for: indexPath)
            let sesameBotCell = cell as! SesameBotListCell
            sesameBotCell.sesameBot = sesameBot
        } else if let bikeLock = device as? CHSesameBike {
            cell = tableView.dequeueReusableCell(withIdentifier: "BikeLockListCell", for: indexPath)
            let bikeLockCell = cell as! BikeLockListCell
            bikeLockCell.bikeLock = bikeLock
        } else if let wifiModule2 = device as? CHWifiModule2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "WifiModule2ListCell", for: indexPath)
            let wifiModule2Cell = cell as! WifiModule2ListCell
            wifiModule2Cell.wifiModule2 = wifiModule2
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let device = devices[indexPath.row]
        if let sesame2 = device as? CHSesame2 {
            navigateToSesame2History(sesame2)
        } else if let sesameBot = device as? CHSesameBot {
            navigateToSesameBotSettingViewController(sesameBot)
        } else if let bikeLock = device as? CHSesameBike {
            navigateToBikeLockSettingViewController(bikeLock)
        } else if let wifiModule2 = device as? CHWifiModule2 {
            navigateToWifiModule2SettingViewController(wifiModule2)
        }
    }
    
    // MARK: - Navigation
    func navigateToSesame2History(_ sesame2: CHSesame2) {
        let sesame2HistoryViewController = Sesame2HistoryViewController.instanceWithSesame2(sesame2) {
            self.getKeysFromCache()
        }
        navigationController?.pushViewController(sesame2HistoryViewController,
                                                 animated: true)
    }
    
    func navigateToSesame2Setting(_ sesame2: CHSesame2) {
        let settingViewController = Sesame2SettingViewController.instanceWithSesame2(sesame2) { _ in
            self.getKeysFromCache()
        }
        navigationController?.pushViewController(settingViewController, animated: true)
    }
    
    func navigateToSesame2LockAngleSetting(_ sesame2: CHSesame2) {
        let angleSettingViewController = LockAngleSettingViewController.instanceWithSesame2(sesame2) {
            executeOnMainThread {
                self.getKeysFromCache()
            }
        }
        self.navigationController?.pushViewController(angleSettingViewController, animated: true)
    }
    
    func navigateToSesameBotSettingViewController(_ sesameBot: CHSesameBot) {
        
        let switchSettingViewController = SesameBotSettingViewController.instanceWithSwitch(sesameBot) {
            self.getKeysFromCache()
        }
        navigationController?.pushViewController(switchSettingViewController,
                                                 animated: true)
    }
    
    func navigateToBikeLockSettingViewController(_ bikeLock: CHSesameBike) {
        let bikeLockSettingViewController = BikeLockSettingViewController.instanceWithBikeLock(bikeLock) {
            self.getKeysFromCache()
        }
        navigationController?.pushViewController(bikeLockSettingViewController,
                                                 animated: true)
    }
    
    func navigateToWifiModule2SettingViewController(_ wifiModule2: CHWifiModule2, isFromRegister: Bool = false) {
        let wifiModule2SettingViewController = WifiModule2SettingViewController.instanceWithWifiModule2(wifiModule2, isFromRegister: isFromRegister) {
            executeOnMainThread {
                self.getKeysFromCache()
            }
        }
        navigationController?.pushViewController(wifiModule2SettingViewController,
                                                 animated: true)
    }
}

// MARK: - PopUpMenuDelegate
extension SesameDeviceListViewController: PopUpMenuDelegate {
    
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        if self.popUpMenuControl.superview != nil {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }
    
    private func hideMoreMenu(animated: Bool = true) {
        popUpMenuControl.hide(animated: animated)
    }
    
    private func showMoreMenu() {
        popUpMenuControl.show(in: UIApplication.shared.keyWindow!)
    }
    
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        switch item.type {
        case .addSesame2:
            presentRegisterViewController()
        case .receiveKey:
            presentScanViewController()
        }
        hideMoreMenu(animated: false)
    }
    
    // MARK: Navigation
    func presentRegisterViewController() {
        let registerSesameDeviceViewController = RegisterSesameDeviceViewController.instance { registeredDevice in
            if let wifiModule2 = registeredDevice as? CHWifiModule2 {
                self.refreshControl.endRefreshing()
                self.noContentRefreshControl.endRefreshing()
                self.navigateToWifiModule2SettingViewController(wifiModule2, isFromRegister: true)
            } else if let sesame2 = registeredDevice as? CHSesame2 {
                self.refreshControl.endRefreshing()
                self.noContentRefreshControl.endRefreshing()
                self.navigateToSesame2LockAngleSetting(sesame2)
            } else {
                self.tableView.reloadData()
                self.refreshControl.beginRefreshing()
                self.noContentRefreshControl.beginRefreshing()
                self.getKeysFromCache()
            }
            
        }
        present(registerSesameDeviceViewController.navigationController!, animated: true, completion: nil)
    }
    
    func presentScanViewController() {
        let qrCodeScanViewController = QRCodeScanViewController.instance() { qrCodeType in
            executeOnMainThread {
                if qrCodeType == .sk {
                    self.refreshControl.beginRefreshing()
                    self.noContentRefreshControl.beginRefreshing()
                    self.getKeysFromCache()
                    
                }
            }
        }
        present(qrCodeScanViewController, animated: true, completion: nil)
    }
}

// MARK: - Designated initializer
extension SesameDeviceListViewController {
    static func instance() -> SesameDeviceListViewController {
        let sesame2ListViewController = SesameDeviceListViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController()
        navigationController.pushViewController(sesame2ListViewController, animated: false)
        return sesame2ListViewController
    }
}
