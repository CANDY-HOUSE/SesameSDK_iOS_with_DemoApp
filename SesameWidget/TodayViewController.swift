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
import AWSMobileClient

public class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var tableView: UITableView!
    var devices = [CHSesame2]()
    var informations = [String]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
                        self.devices = sesame2.data
                        self.devices
                            .sort(by: {
                                let name1 = Sesame2Store.shared.getPropertyForDevice($0).name ?? $0.deviceId.uuidString
                                let name2 = Sesame2Store.shared.getPropertyForDevice($1).name ?? $1.deviceId.uuidString
                                return name1 < name2
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
