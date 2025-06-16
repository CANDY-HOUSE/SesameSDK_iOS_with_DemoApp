//
//  FriendKeyShareSelectionViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class FriendKeyShareSelectionViewController: UITableViewController, ShareAlertConfigurator {
    
    var dismissHandler: (()->Void)?
    private var friend: CHUser!
    
    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            L.d("[friend]拿取手機內設備列表")
            if case let .success(devices) = result {
                chDevices = devices.data
                    .filter {
                        if $0 is CHHub3  { return true }
                        else if $0 is CHWifiModule2  { return false }
                        return true
                    }
                    .filter {
                        $0.keyLevel != KeyLevel.guest.rawValue
                    }
            }
        }
        return chDevices
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = dismissButtonItem
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
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = keys[indexPath.row].deviceName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = keys[indexPath.row]
        modalSheetOnFriendsByRoleLevel(device: device, friend: self.friend, view: view) { isSuccess in
            executeOnMainThread {
                self.dismiss(animated: true, completion: nil)
                self.dismissHandler?()
            }
        }
    }
    
    static func instanceWithFriend(_ friend: CHUser, dismissHandler: (()->Void)?) -> FriendKeyShareSelectionViewController {
        let friendKeyShareSelectionViewController = FriendKeyShareSelectionViewController(nibName: nil, bundle: nil)
        friendKeyShareSelectionViewController.friend = friend
        friendKeyShareSelectionViewController.dismissHandler = dismissHandler
        _ = UINavigationController(rootViewController: friendKeyShareSelectionViewController)
        return friendKeyShareSelectionViewController
    }
}
