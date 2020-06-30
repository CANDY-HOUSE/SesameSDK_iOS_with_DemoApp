//
//  TodayViewController.swift
//  locker
//
//  Created by tse on 2019/10/15.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import NotificationCenter
import SesameSDK
import AWSMobileClient

let CHAppGroupWidget = "group.candyhouse.widget"

public class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var tableView: UITableView!
    var sesameDevicesMap: [String: CHSesameBleInterface] = [:]
    var devices = [CHSesameBleInterface]()
    var informations = [String]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        CHAuthHelper.shared.initialize()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "information")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        L.d("viewWillAppear")
        CHBleManager.shared.enableScan()
        logInUserIfNeeded()
        loadLocalDevices()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        L.d("離開widget")
        CHBleManager.shared.disableScan()
        CHBleManager.shared.disConnectAll()
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
    
    func logInUserIfNeeded() {
        let result = CHUIKeychainManager.shared.getUsernameAndPassword()
        guard let username = result.username,
            let password = result.password else {
                L.d("Not found in keychain.")
                informations = ["\("co.candyhouse.sesame-sdk-test-app.locker.resignIn".localStr)"]
                // Force sign out widget user since no user found in keychain.
                if AWSMobileClient.default().isSignedIn {
                    CHAuthHelper.shared.signOut()
                }
                notifyTable()
            return
        }
        
        if AWSMobileClient.default().isSignedIn,
            CHUIKeychainManager.shared.isWidgetNeedSignIn() == true {
            L.d("ReSign in user.")
            CHAuthHelper.shared.signOut()
            CHAuthHelper
                .shared
                .signIn(username: username,
                        password: password) {
                            if $0 == true {
                                L.d("Signed in Succeed.")
                            } else {
                                L.d("Signed in failed.")
                            }
            }
        } else if AWSMobileClient.default().isSignedIn == false {
            CHAuthHelper
                .shared
                .signIn(username: username,
                        password: password) {
                            if $0 == true {
                                L.d("Signed in Succeed.")
                            } else {
                                L.d("Signed in failed.")
                            }
            }
        } else {
            L.d("User already signed in.")
        }
    }
    
    func loadLocalDevices()  {
            L.d("Load local devices.")
            DispatchQueue.main.async {
                CHBleManager.shared.getMyDevices(){ result in
                    if case .success(let devices) = result {
                        self.devices += devices
                        self.devices.forEach({
                            self.sesameDevicesMap.updateValue($0, forKey: $0.deviceId!.uuidString)
                        })
                    }
                    self.notifyTable()
                }
            }
        }
        
    func notifyTable()  {
        DispatchQueue.main.async {
            self.devices.removeAll()
            self.sesameDevicesMap.forEach({
                self.devices.append($1)}
            )
            
            self.devices
                .sort(by: {
                    let name1 = SSMStore.shared.getDevicePropertyFromDBForDevice($0)?.name ?? $0.deviceId.uuidString
                    let name2 = SSMStore.shared.getDevicePropertyFromDBForDevice($1)?.name ?? $1.deviceId.uuidString
                    return name1 < name2
                })
            
            if self.devices.count == 0 && self.informations.count == 0 {
                self.informations = ["co.candyhouse.sesame-sdk-test-app.locker.noDeviceFound".localStr]
            }
            self.tableView.reloadData()
        }
    }
}

extension TodayViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count > 0 ? devices.count : informations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if devices.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SSMCell", for: indexPath) as! DeviceCell
            cell.ssm = devices[indexPath.row]
            return  cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "information", for: indexPath)
            cell.textLabel?.text = informations[indexPath.row]
            return  cell
        }
    }
}
