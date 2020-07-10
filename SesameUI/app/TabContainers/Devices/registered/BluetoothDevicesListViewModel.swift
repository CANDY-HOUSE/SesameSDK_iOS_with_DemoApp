//
//  BluetoothDevicesListViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import WatchConnectivity

public protocol BluetoothDevicesListViewModelDelegate: class {
    func bluetootheDevicesListViewDidTappedSSM(_ ssm: CHSesame2)
    func newSesameTapped()
    func scanViewTapped()
    func enterTestMode(ssm: CHSesame2)
}

final class BluetoothDevicesListViewModel: ViewModel {
    var coordinator: BluetoothDevicesListCoordinator
    var delegate: BluetoothDevicesListViewModelDelegate?
    private var sesameDevices: [CHSesame2] = []
    
    public var statusUpdated: ViewStatusHandler?
    
    init(coordinator: BluetoothDevicesListCoordinator) {
        self.coordinator = coordinator
    }
    
    public var numberOfSections: Int {
        1
    }

    public func numberOfRowsInSection(_ section: Int) -> Int {
        sesameDevices.count
    }
    
    public func cellViewModelAt(_ indexPath: IndexPath) -> BluetoothDeviceCellViewModel {
        let bluetoothDeviceCellViewModel = BluetoothDeviceCellViewModel(ssm: sesameDevices[indexPath.row])
        bluetoothDeviceCellViewModel.delegate = self
        return bluetoothDeviceCellViewModel
    }
    
    public func didSelectRowAt(_ indexPath: IndexPath) {
        delegate?.bluetootheDevicesListViewDidTappedSSM(sesameDevices[indexPath.row])
    }

    @objc
    public func loadLocalDevices() {
        self.statusUpdated?(.loading)
        
        CHBleManager.shared.getSesames() { result in
            switch result {
            case .success(let ssms):
                self.sesameDevices = ssms
                var keys = [String: Any]()
                for ssm in ssms {
                    if let key = ssm.getKey() {
                        keys[ssm.deviceId.uuidString] = key
                    }
                }
                WCSession.default.sendMessage(keys, replyHandler: nil, errorHandler: nil)
//                guard let storeURL = try? CHBleManager.shared.backupStoreURL() else {
//                    return
//                }
//                WCSession.default.transferFile(storeURL, metadata: nil)
                
//                guard let ssmStoreURL = try? SSMStore.shared.backupStoreURL() else {
//                    return
//                }
//                WCSession.default.transferFile(ssmStoreURL, metadata: nil)
                L.d("Retrieved \(ssms.count) devices, sent db to watch.")
                self.statusUpdated?(.received)
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    public func popUpMenuTappedOnItem(_ item: PopUpMenuItem) {
        switch item.type {
        case .addFriends:
            delegate?.scanViewTapped()
        case .addDevices:
            delegate?.newSesameTapped()
        }
    }
    
    deinit {
//        L.d("BluetoothDevicesListViewModel")
    }
}

// MARK: - Test mode
extension BluetoothDevicesListViewModel: BluetoothDeviceCellViewModelDelegate {
    func enterTestModeTapped(ssm: CHSesame2) {
        delegate?.enterTestMode(ssm: ssm)
    }
    
    func testSwitchToggled(isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: "testMode")
        statusUpdated?(.received)
    }
    
    var isTestModeOn: Bool {
        UserDefaults.standard.bool(forKey: "testMode")
    }
}
