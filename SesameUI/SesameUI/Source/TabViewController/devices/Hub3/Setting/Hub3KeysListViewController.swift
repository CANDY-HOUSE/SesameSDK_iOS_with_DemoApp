//
//  Hub3KeysListViewController.swift
//  SesameUI
//
//  Created by eddy on 2024/1/6.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

class Hub3KeysListViewController: CHBaseViewController {
    
    var selectionHandler: ((CHDevice)->Void)?
    var device: CHHub3!
    var tableView: UITableView!

    lazy var keys: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { [weak self] result in
            if case let .success(devices) = result {
                chDevices = devices.data.filter { [
                    .bikeLock2,
                    .sesame5,
                    .sesame5Pro,
                    .sesame5US,
                    .sesameBot2,
                    .sesameTouch,
                    .sesameTouch2,
                    .sesameTouchPro,
                    .sesameTouchPro2,
                    .sesameFace,
                    .sesameFace2,
                    .sesameFacePro,
                    .sesameFacePro2,
                    .sesame6Pro,
                    .sesameFaceAI,
                    .sesameFaceProAI,
                    .bleConnector].contains($0.productModel) }
            }
        }
        return chDevices
            .filter { !device.sesame2Keys.keys.contains( $0.deviceId.uuidString) }
            .filter { $0.keyLevel < KeyLevel.guest.rawValue }
            .sorted { left, right -> Bool in
                left.compare(right)
            }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
    }
    
    func configureTable() {
        tableView = UITableView.ch_tableView(view, .plain, "candyhouse.no_data".localized, nil, false)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView?.isHidden = !self.keys.isEmpty
    }
}

extension Hub3KeysListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { keys.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell?.setSeperatorLineEnable()
        }
        cell!.accessoryType = .none
        cell!.textLabel?.text = keys[indexPath.row].deviceName
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let willInsertDevice = keys[indexPath.row]
        ViewHelper.showLoadingInView(view: self.view)
        device.insertSesame(willInsertDevice, nickName: willInsertDevice.deviceName, matterProductModel: willInsertDevice.productModel.defaultMatterRole) { [weak self] result in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self?.view)
                if case let .failure(err) = result {
                    self?.view.makeToast(err.errorDescription())
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

extension Hub3KeysListViewController {
    static func instance(_ device: CHHub3, _ selectionHandler: @escaping (CHDevice)->Void) -> Hub3KeysListViewController {
        let vc = Hub3KeysListViewController(nibName: nil, bundle: nil)
        vc.device = device
        vc.selectionHandler = selectionHandler
        return vc
    }
}
