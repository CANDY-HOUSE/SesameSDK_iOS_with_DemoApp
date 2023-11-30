//
//  TodayViewController.swift
//  locker
//  [Widget]
//  Created by tse on 2019/10/15.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import NotificationCenter
import SesameSDK

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var tableView: UITableView!
    var devices: [CHDevice] = []
    var extensionListener = CHExtensionListener()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.containingAppDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.containingAppWillResignActive)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
        tableView.separatorStyle = .none
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "information")
        tableView.register(UINib(nibName: "Sesame5ListCell", bundle: nil),forCellReuseIdentifier: "Sesame5ListCell")
//        tableView.register(UINib(nibName: "Sesame2ListCell", bundle: nil),forCellReuseIdentifier: "Sesame2ListCell")
//        tableView.register(UINib(nibName: "SesameBotListCell", bundle: nil), forCellReuseIdentifier: "SesameBotListCell")
//        tableView.register(UINib(nibName: "BikeLockListCell", bundle: nil), forCellReuseIdentifier: "BikeLockListCell")
//        tableView.register(UINib(nibName: "SesameButtonListCell", bundle: nil), forCellReuseIdentifier: "SesameButtonListCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CHExtensionListener.post(notification: CHExtensionListener.widgetDidBecomeActive)
        CHBluetoothCenter.shared.enableScan() { res in }
        loadLocalDevices()
        Sesame2Store.shared.refreshDB()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CHBluetoothCenter.shared.disableScan(){res in}
        CHBluetoothCenter.shared.disConnectAll{res in}
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if case .compact = activeDisplayMode {
            preferredContentSize = maxSize
        } else {
            if devices.isEmpty {
                preferredContentSize.height = 120
            } else {
                preferredContentSize.height = CGFloat(devices.count * 120)
            }
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    func loadLocalDevices()  {
        CHDeviceManager.shared.getCHDevices { getResult in
            switch getResult {
            case .success(let devices):
                
                self.devices = devices.data
                    .filter({ ($0 is CHSesameConnector) == false })
                    .sorted(by: { left, right -> Bool in left.compare(right) })

                CHDeviceManager.shared.receiveCHDeviceKeys(self.devices.compactMap({ $0.getKey() })) { _ in }
                executeOnMainThread {
                    if self.devices.isEmpty {
                        self.preferredContentSize.height = 120
                    } else {
                        self.preferredContentSize.height = CGFloat(self.devices.count * 120)
                    }
                }
            case .failure(_):
                break
            }
        }
    }
    
    deinit {
        extensionListener.unregisterAll()
        CHExtensionListener.post(notification: CHExtensionListener.widgetWillResignActive)
    }
}

extension TodayViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if devices.isEmpty {
            return 1
        } else {
            return devices.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if devices.isEmpty {
            cell = tableView.dequeueReusableCell(withIdentifier: "information", for: indexPath)
            cell.textLabel?.text = "co.candyhouse.sesame2.locker.noDeviceFound".localized
        } else {
            let device = devices[indexPath.row]
//            if let ss5 = device as? CHDevice {
               cell = tableView.dequeueReusableCell(withIdentifier: "Sesame5ListCell", for: indexPath)
               let ss5Cell = cell as! Sesame5ListCell
               ss5Cell.device = device
//           }
//            else if let sesame2 = device as? CHSesame2 {
//                cell = tableView.dequeueReusableCell(withIdentifier: "Sesame2ListCell", for: indexPath)
//                let sesame2Cell = cell as! Sesame2ListCell
//                sesame2Cell.sesame2 = sesame2
//            } else if let sesameBot = device as? CHSesameBot {
//                cell = tableView.dequeueReusableCell(withIdentifier: "SesameBotListCell", for: indexPath)
//                let sesameBotCell = cell as! SesameBotListCell
//                sesameBotCell.sesameBot = sesameBot
//            } else if let bikeLock = device as? CHSesameBike {
//                cell = tableView.dequeueReusableCell(withIdentifier: "BikeLockListCell", for: indexPath)
//                let bikeLockCell = cell as! BikeLockListCell
//                bikeLockCell.bikeLock = bikeLock
//            }else if let sesameButton = device as? CHSesameButton {
//                cell = tableView.dequeueReusableCell(withIdentifier: "SesameButtonListCell", for: indexPath)
//                let sesameButtonCell = cell as! SesameButtonListCell
//                sesameButtonCell.sesameButton = sesameButton
//            }
        }
        cell.selectionStyle = .none
        return cell
    }
}

extension TodayViewController: CHExtensionListenerDelegate {
    public func receiveExtensionNotification(_ notificationIdentifier: String) {
        if notificationIdentifier == CHExtensionListener.containingAppDidBecomeActive {
            self.viewWillDisappear(true)
        } else if notificationIdentifier == CHExtensionListener.containingAppWillResignActive {
            self.viewWillAppear(true)
        }
    }
}
