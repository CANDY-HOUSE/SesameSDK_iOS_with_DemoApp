//
//  WifiModule2SettingViewController+SesameList.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

private let cellIdentifier = "cell"

extension WifiModule2SettingViewController: UITableViewDataSource, UITableViewDelegate {
    @IBAction func addSesameTapped(_ sender: Any) {
        let wifiModule2KeysListViewController = WifiModule2KeysListViewController.instanceWithSelectionHandler { device in
            self.insertCHDeviceToWM2(device)
        }
        present(wifiModule2KeysListViewController.navigationController!, animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        wifiModuleDeviceModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wifiModuleDeviceModel = wifiModuleDeviceModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        cell.selectionStyle = .none
        let foundDevice = localDevices.filter {
            $0.deviceId.uuidString == wifiModuleDeviceModel.sesame2Key
        }.first
        if foundDevice != nil {
            cell.textLabel?.text = foundDevice?.deviceName
        } else {
            cell.textLabel?.text = wifiModuleDeviceModel.sesame2Key
        }
        return cell
    }
    
    func image(_ image: UIImage, withSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = withSize.width  / image.size.width
        let heightRatio = withSize.height / image.size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delete = UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized,
                                            style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            let sesame2 = self.wifiModuleDeviceModels[indexPath.row]
            self.wifiModule2.removeCHDevice(keyId: sesame2.sesame2Key) { result in
                executeOnMainThread {
                    if case let .failure(error) = result {
                        self.view.makeToast(error.errorDescription())
                    } else {
                        self.wifiModuleDeviceModels.removeAll { $0.sesame2Key == sesame2.sesame2Key }
                        self.sesame2ListView.reloadData()
                    }
                    ViewHelper.hideLoadingView(view: self.view)
                }
            }
            
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(delete)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }
    
    func insertCHDeviceToWM2(_ device: CHDevice) {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.view)
        }
        wifiModule2.insertCHDevice(device) { result in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
}

class WifiModule2KeysListViewController: UITableViewController {
    
    var selectionHandler: ((CHDevice)->Void)?
    
    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data.filter {
                    if $0 is CHSesame2 || $0 is CHSesameBot || $0 is CHSesameBike {
                        return true
                    } else {
                        return false
                    }
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
        tableView.tableFooterView = UIView()
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
        let key = keys[indexPath.row]
        selectionHandler?(key)
        dismiss(animated: true, completion: nil)
    }
    
    static func instanceWithSelectionHandler(_ selectionHandler: @escaping (CHDevice)->Void) -> WifiModule2KeysListViewController {
        let wifiModule2KeysListViewController = WifiModule2KeysListViewController(nibName: nil, bundle: nil)
        wifiModule2KeysListViewController.selectionHandler = selectionHandler
        _ = UINavigationController(rootViewController: wifiModule2KeysListViewController)
        return wifiModule2KeysListViewController
    }
}
