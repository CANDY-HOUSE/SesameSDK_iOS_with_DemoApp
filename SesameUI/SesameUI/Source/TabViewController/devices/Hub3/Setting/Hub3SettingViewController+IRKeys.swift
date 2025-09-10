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
import Combine

extension Hub3SettingViewController {
    
    private var cancellables: Set<AnyCancellable> {
        get { return objc_getAssociatedObject(self, "hub3_settings_ir") as? Set<AnyCancellable> ?? Set<AnyCancellable>() }
        set { objc_setAssociatedObject(self, "hub3_settings_ir", newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
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
                self.navigationController?.pushViewController(RemoteTypeListVC.instance((self.device as! CHHub3).deviceId.uuidString.uppercased()), animated: true)
            }
        }
        addIRKeysButtonView.setColor(.darkText)
        addIRKeysButtonView.title = "co.candyhouse.hub3.bindIRDeviceTitle".localized
        contentStackView.addArrangedSubview(addIRKeysButtonView)
        setupIRDeviceObserver()
    }
    
    private func setupIRDeviceObserver() {
        let hub3DeviceId:String = (device as! CHHub3).deviceId.uuidString.uppercased()
        IRRemoteRepository.shared.statePublisher
            .map { [weak self] state in
                guard let self = self else { return [] }
                return state.remoteMap[String(hub3DeviceId)] ?? []
            }
//            .removeDuplicates { (oldList: [IRRemote], newList: [IRRemote]) in
//                guard oldList.count == newList.count else { return false }
//                return zip(oldList, newList).allSatisfy { $0.uuid == $1.uuid }
//            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remoteList in
                self?.refreshIRKeys()
            }
            .store(in: &cancellables)
    }
    
    func removeRemoteUpdateListener() {
        cancellables.removeAll()
    }
    
    func refreshIRKeys() {
        wifiModuleIRModels = getCurrentHub3IRDeviceList()
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
    
    func getCurrentHub3IRDeviceList() -> [IRRemote] {
       return IRRemoteRepository.shared.getRemotesByKey((device as! CHHub3).deviceId.uuidString.uppercased())
    }
    
    //bug【1001351】iOS 与 Android 双端一致：在进入详情界面时更新最新的红外设备列表
    func fetchIrDevices() {
        CHIRManager.shared.fetchIRDevices((device as! CHHub3).deviceId.uuidString.uppercased()) { _ in }
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
                let hub3DeviceId = (device as! CHHub3).deviceId.uuidString.uppercased()
                CHIRManager.shared.deleteIRDevice(hub3DeviceId, irDeviceModel.uuid) { [weak self] response in
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
            guard let remote = getCurrentHub3IRDeviceList().first(where: { $0.uuid == irDeviceModel.uuid }) else { return }
            let hub3DeviceId = hub3.deviceId.uuidString.uppercased()
            hub3.preference.updateSelectExpandIndex(indexPath.row)
            switch remote.type {
            case IRType.DEVICE_REMOTE_CUSTOM:
                navigationController?.pushViewController(RemoteLearnVC.instance(hub3DeviceId: hub3DeviceId, remote: remote), animated: true)
                break
            case IRType.DEVICE_REMOTE_AIR, IRType.DEVICE_REMOTE_TV, IRType.DEVICE_REMOTE_LIGHT:
                let vc = RemoteControlVC(irRemote: remote,hub3DeviceId: hub3DeviceId)
                self.navigationController?.pushViewController(vc, animated: true)
                break
            default: break
            }
        }), at: 0)
        modalSheet(AlertModel(title: nil, message: irDeviceModel.alias, sourceView: tableView.cellForRow(at: indexPath), items:optItems ))
    }
}
