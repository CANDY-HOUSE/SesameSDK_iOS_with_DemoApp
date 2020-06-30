//
//  MyDeviceViewController.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/08/30.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

class MyDeviceViewController: BaseLightViewController {
    var device: CHDeviceProfile?
    var listView: MyDevicesListViewController?
    var userList = [CHDeviceMember]()

    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var refreshUserList: UIButton!
    @IBOutlet weak var userTable: UITableView!

    override func viewDidLoad() {
        detailLabel.text = "Device ID: \(device!.deviceId.uuidString)\nCustomName: \(device!.customName ?? "")\nDevice Model: \(device!.model.rawValue)\nBluetooth Identity: \(device!.bleIdentity?.toHexString() ?? "")\nAccess Level: \(device!.accessLevel.rawValue)\n"
        detailLabel.sizeToFit()
        detailLabel.numberOfLines = 0
    }

    @IBAction func unregisterDidPress(_ sender: Any) {
        weak var weakSelf = self
        ViewHelper.showLoadingInView(view: self.view)
//        device?.unregisterDeivce(deviceId: device!.deviceId, model: device!.model, completion: { (result) in
//            ViewHelper.hideLoadingView(view: weakSelf?.view)
//            if result.success {
//                self.listView?.flushDevice { (_) in
//                    DispatchQueue.main.async {
//                        weakSelf?.presentingViewController?.dismiss(animated: true, completion: nil)
//                    }
//                }
//            } else {
//                ViewHelper.showAlertMessage(title: "Error", message: "unregister failed: \(result.errorDescription ?? "unknown reason")", actionTitle: "ok", viewController: weakSelf!)
//            }
//        })

        
    }

    @IBAction func didPressUserRefresh(_ sender: Any) {
        guard self.device?.deviceId != nil else {
            ViewHelper.showAlertMessage(title: "Ooops", message: "Incomplete Device Info. deviceId is missing.", actionTitle: "OK", viewController: self)
            return
        }
        weak var weakSelf = self
        CHAccountManager.shared.deviceManager.getDeviceMembers(self.device!.deviceId) { (_, result, users) in
            if result.success {
                guard users == nil else {
                    DispatchQueue.main.async {
                        weakSelf?.userList = users!
                        weakSelf?.userTable.reloadData()
                    }
                    return
                }
            } else {
                guard weakSelf == nil else {
                    ViewHelper.alert("Ooops", "Get device user list failed.", weakSelf!)
                    return
                }
            }
        }
    }

    func deleteUser(_ user: CHDeviceMember) {
        guard device?.bleIdentity != nil else {
            ViewHelper.showAlertMessage(title: "Ooops", message: "Incomplete device detailsj to connect: missing bleIdentity", actionTitle: "ok", viewController: self)
            return
        }

        guard user.userId != CHAccountManager.shared.candyhouseUserId else {
            ViewHelper.showAlertMessage(title: "Ooops", message: "You can't delete yourself dear 😂", actionTitle: "ok", viewController: self)
            return
        }

        if let blesesame = CHBleManager.shared.getSesame(bleIdentity: (device?.bleIdentity)!) {
            ViewHelper.showLoadingInView(view: self.view)
            do {
                try blesesame.connect()
                let waitTime = blesesame.gattStatus == .established ? 0 : 5
                Thread.sleep(forTimeInterval: TimeInterval(waitTime))
                if blesesame.gattStatus == .established {
                    guard user.accessId != nil else {
                        ViewHelper.hideLoadingView(view: self.view)
                        ViewHelper.showAlertMessage(title: "Oops", message: "incomplete user info: missing accessId", actionTitle: "ok", viewController: self)
                        return
                    }
                    try blesesame.revokeKey(user.accessId!) { (result) in
                        if result.success {
                            self.didPressUserRefresh(self)
                            ViewHelper.hideLoadingView(view: self.view)
                            ViewHelper.showAlertMessage(title: "Successful", message: "You had remove this user", actionTitle: "ok", viewController: self)
                        } else {
                            ViewHelper.hideLoadingView(view: self.view)
                            ViewHelper.showAlertMessage(title: "Oops", message: "Revoke the user failed: \(result.errorDescription ?? "unknown error")", actionTitle: "ok", viewController: self)
                        }
                    }
                } else {
                    ViewHelper.showAlertMessage(title: "Oops", message: "Connect to the Sesame failed, please try again", actionTitle: "ok", viewController: self)
                    ViewHelper.hideLoadingView(view: self.view)
                }
            } catch let error {
                ViewHelper.showAlertMessage(title: "Oops", message: "ble coperation error:\(error.localizedDescription)", actionTitle: "ok", viewController: self)
                ViewHelper.hideLoadingView(view: self.view)
            }
        } else {
            ViewHelper.showAlertMessage(title: "Oops", message: "Something went wrong, there is no such Sesame nearby.", actionTitle: "ok", viewController: self)
            ViewHelper.hideLoadingView(view: self.view)
        }
    }
}

extension MyDeviceViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = userTable.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let user = userList[indexPath.row]
        if user.userId?.uuidString == CHAccountManager.shared.candyhouseUserId?.uuidString {
            cell?.textLabel?.text = AWSCognitoOAuthService.shared.signedInUsername ?? "(You)"
        } else {
            cell?.textLabel?.text = user.userId?.uuidString ?? "\(user.type.rawValue): \(user.accessId?.toHexString().prefix(5) ?? "unknown")"
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let user = userList[indexPath.row]
        if editingStyle == .delete {
            self.deleteUser(user)
        }
    }
}
