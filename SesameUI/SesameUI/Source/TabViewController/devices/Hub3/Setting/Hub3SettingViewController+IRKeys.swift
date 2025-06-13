//
//  Hub3SettingViewController+IRKeys.swift
//  SesameUI
//
//  Created by eddy on 2024/1/24.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

extension Hub3SettingViewController {
    
    func configureIRKeysTableView() {
        irKeysListView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        irKeysListView.delegate = self
        irKeysListView.dataSource = self
        irKeysListView.isScrollEnabled = false
    }
    
    func configureAddIRKeys() {
        // MARK: Add Sesame Title
        let titleLabelContainer = UIView(frame: .zero)
        CHUIViewGenerator.label("co.candyhouse.hub3.bindIRDeviceHint".localized, superTuple: (titleLabelContainer, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)))
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        irKeysAddHint = titleLabelContainer
        // MARK: Sesame2ListView
        contentStackView.addArrangedSubview(irKeysListView)
        irKeysViewHeight = irKeysListView.autoLayoutHeight(0)
        irKeysListView.separatorColor = .lockGray

        // MARK: Add Sesame Buttom View
        addIRKeysButtonView = CHUIViewGenerator.plain { [unowned self] button,_ in
            if (self.wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true {
                self.navigationController?.pushViewController(Hub3IRDeviceTypesVC.instance(self.device as! CHHub3), animated: true)
            }
        }
        addIRKeysButtonView.setColor(.darkText)
        addIRKeysButtonView.title = "co.candyhouse.hub3.bindIRDeviceTitle".localized
        contentStackView.addArrangedSubview(addIRKeysButtonView)
    }
    
    func refreshIRKeys() {
        wifiModuleIRModels = wifiModule2.irRemotes
        self.irKeysViewHeight.constant = CGFloat(self.wifiModuleIRModels.count) * 50
        self.irKeysListView.reloadData()
    }
    
    func ir_didChangekeys(_ sesame2keys: [String: String]) {
        executeOnMainThread {
            self.refreshIRKeys()
            if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, 
                let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                listViewController.reloadTableView()
            }
        }
    }
}

extension Hub3SettingViewController {
    func ir_tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { wifiModuleIRModels.count }

    func ir_tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }

    func ir_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let IRDeviceModel = wifiModuleIRModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "icons_filled_more", fillColor: .gray))
        cell.selectionStyle = .none
        cell.textLabel?.text = IRDeviceModel.alias
        return cell
    }
    
    func ir_tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let irDeviceModel = wifiModuleIRModels[safe: indexPath.row] else { return }
        var optItems = [
            AlertItem(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive, handler: { [self] _ in
                (device as! CHHub3).deleteIRDevice(irDeviceModel.uuid) { [weak self] response in
                    executeOnMainThread {
                        if case let .failure(err) = response {
                            self?.view.makeToast(err.errorDescription())
                        }
                    }
                }
            }),
            AlertItem.cancelItem()
        ]
        optItems.insert(AlertItem(title: "co.candyhouse.hub3.ssmDetail".localized, handler: { [unowned self] _ in
            guard let hub3 = device as? CHHub3 else { return }
            guard let remote = hub3.irRemotes.first(where: { $0.uuid == irDeviceModel.uuid }) else { return }
            hub3.preference.updateSelectExpandIndex(indexPath.row)
            switch remote.type {
            case IRDeviceType.DEVICE_REMOTE_CUSTOM:
                navigationController?.pushViewController(Hub3IRCustomizeControlVC.instance(device: hub3), animated: true)
                break
            case IRDeviceType.DEVICE_REMOTE_AIR, IRDeviceType.DEVICE_REMOTE_TV, IRDeviceType.DEVICE_REMOTE_LIGHT:
                let handler = IRDeviceType.controlFactory(remote.type, remote.state)
                let vc = Hub3IRRemoteControlVC(irRemote: remote)
                vc.chDevice = (device as! CHHub3)
                self.navigationController?.pushViewController(vc, animated: true)
                break
            default: break
            }
        }), at: 0)
        modalSheet(AlertModel(title: nil, message: irDeviceModel.alias, sourceView: tableView.cellForRow(at: indexPath), items:optItems ))
    }
}
