//
//  Hub3SettingViewController+SesameKeys.swift
//  SesameUI
//
//  Created by eddy on 2024/1/24.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

extension Hub3SettingViewController {
    
    var localDevices: [CHDevice] {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data
                L.d("deviceUUIDS", chDevices.map { $0.deviceId.uuidString })
            }
        }
        return chDevices
    }
    
    func configureSesameTableView() {
        sesame2ListView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        sesame2ListView.delegate = self
        sesame2ListView.dataSource = self
        sesame2ListView.isScrollEnabled = false
    }
    
    func configureAddSesame() {
        // MARK: Add Sesame Title
        let titleLabelContainer = UIView(frame: .zero)
        CHUIViewGenerator.label("co.candyhouse.sesame2.bindSesame2ToHub3".localized, superTuple: (titleLabelContainer, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)))
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Sesame2ListView
        contentStackView.addArrangedSubview(sesame2ListView)
        sesame2ListViewHeight = sesame2ListView.autoLayoutHeight(0)
        sesame2ListView.separatorColor = .lockGray

        // MARK: Add Sesame Buttom View
        addSesameButtonView = CHUIViewGenerator.plain { [unowned self] button,_ in
            if (self.wifiModule2.mechStatus as? CHWifiModule2NetworkStatus)?.isAPWork == true {
                let wifiModule2KeysListViewController = Hub3KeysListViewController.instance(wifiModule2) { [unowned self] device in
                    self.navigationController?.popViewController(animated: true)
                    self.wifiModule2.insertSesame(device) { result in
                        executeOnMainThread {
                            if case let .failure(error) = result {
                                self.view.makeToast(error.errorDescription())
                            }
                        }
                    }
                }
                self.navigationController?.pushViewController(wifiModule2KeysListViewController, animated: true)
            }
        }
        if self.wifiModuleDeviceModels.count <  5 {
            addSesameButtonView.setColor(.darkText)
        } else {
            addSesameButtonView.setColor(.sesame2Gray)
        }
        
        addSesameButtonView.title = "co.candyhouse.sesame2.addSesameToWM2".localized
        sesameExclamationContainerView = UIView(frame: .zero)
        let sesameExclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed)) // ！驚嘆號！
        sesameExclamation.contentMode = .scaleAspectFit
        sesameExclamationContainerView.addSubview(sesameExclamation)
        addSesameButtonView.appendViewToTitle(sesameExclamationContainerView)
        sesameExclamation.autoLayoutWidth(20)
        sesameExclamation.autoLayoutHeight(20)
        sesameExclamation.autoPinCenterY()
        
        contentStackView.addArrangedSubview(addSesameButtonView)
    }
    
    func refreshSesameKeys() {
        wifiModuleDeviceModels = wifiModule2.sesame2Keys.sorted { $0.value < $1.value }.compactMap{ $0.key }
        L.d("[wm2]",wifiModuleDeviceModels)
        self.sesame2ListViewHeight.constant = CGFloat(self.wifiModuleDeviceModels.count) * 50
        self.sesame2ListView.reloadData()
    }
    
    func ssm_didChangekeys(_ sesame2keys: [String: String]) {
        executeOnMainThread {
            self.refreshSesameKeys()
            self.refreshUI()
        }
    }
}

extension Hub3SettingViewController {
    
    func ssm_tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { wifiModuleDeviceModels.count }

    func ssm_tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }

    func ssm_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wifiModuleDeviceModel = wifiModuleDeviceModels[indexPath.row]
        L.d("will search", wifiModuleDeviceModel)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        cell.selectionStyle = .none
        let foundDevice = localDevices.first(where: { $0.deviceId.uuidString == wifiModuleDeviceModel })
        if foundDevice != nil {
            cell.textLabel?.text = foundDevice?.deviceName
        } else {
            cell.textLabel?.text = wifiModuleDeviceModel
        }
        return cell
    }
    
    func ssm_tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetDeviceId = self.wifiModuleDeviceModels[indexPath.row]
        var optItems = [
            AlertItem(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive, handler: { [unowned self] _ in
                self.handleDeleteItem(targetDeviceId)
            }),
            AlertItem.cancelItem()
        ]
        modalSheet(AlertModel(title: nil, message: localDevices.filter {
            $0.deviceId.uuidString == targetDeviceId
        }.first?.deviceName ?? targetDeviceId, sourceView: tableView.cellForRow(at: indexPath), items:optItems ))
    }
    
    private func handleDeleteItem(_ key: String) {
        self.wifiModule2.removeSesame(tag: key) { result in
            executeOnMainThread {
                if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                } else {
                    self.wifiModuleDeviceModels.removeAll { $0 == key }
                    self.sesame2ListView.reloadData()
                }
                ViewHelper.hideLoadingView(view: self.view)
            }
        }
    }
}
