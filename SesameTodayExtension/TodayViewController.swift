//
//  TodayViewController.swift
//  locker
//
//  Created by tse on 2019/10/15.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import NotificationCenter
import SesameSDK

public class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var tableView: UITableView!
    var devices = [CHSesame2]()
    var informations = [String]()
    var extensionListener = CHExtensionListener()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.containingAppDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.containingAppWillResignActive)
        CHExtensionListener.post(notification: CHExtensionListener.widgetDidBecomeActive)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "information")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        L.d("viewWillAppear")
        CHBleManager.shared.enableScan(){res in

        }
        loadLocalDevices()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        L.d("離開widget")
        CHBleManager.shared.disableScan(){res in}
        CHBleManager.shared.disConnectAll{res in}
    }
    
    public func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if case .compact = activeDisplayMode {
            preferredContentSize = maxSize
        } else {
            preferredContentSize.height = CGFloat((devices.count) * 110)
        }
    }

    public func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        L.d("widgetPerformUpdate")
        completionHandler(NCUpdateResult.newData)
    }
    
    func loadLocalDevices()  {
            L.d("Load local devices.")
            DispatchQueue.main.async {
                CHDeviceManager.shared.getSesame2s(){ result in
                    if case .success(let sesame2) = result {
                        self.devices = sesame2.data.sorted(by: {
                            $0.compare($1)
                        })
                    }
                    self.notifyTable()
                }
            }
        }
        
    func notifyTable()  {
        DispatchQueue.main.async {
            if self.devices.count == 0 && self.informations.count == 0 {
                self.informations = ["co.candyhouse.sesame-sdk-test-app.locker.noDeviceFound".localized]
            }
            self.tableView.reloadData()
        }
    }
    
    deinit {
        extensionListener.unregisterAll()
        CHExtensionListener.post(notification: CHExtensionListener.widgetWillResignActive)
    }
}

extension TodayViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count > 0 ? devices.count : informations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if devices.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
            cell.sesame2 = devices[indexPath.row]
            cell.selectionStyle = .none
            return  cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "information", for: indexPath)
            cell.textLabel?.text = informations[indexPath.row]
            cell.selectionStyle = .none
            return  cell
        }
    }
}

extension TodayViewController: CHExtensionListenerDelegate {
    public func receiveNotification(_ notificationIdentifier: String) {
        if notificationIdentifier == CHExtensionListener.containingAppDidBecomeActive {
            self.viewWillDisappear(true)
        } else if notificationIdentifier == CHExtensionListener.containingAppWillResignActive {
            self.viewWillAppear(true)
        }
    }
}
