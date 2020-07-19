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
    func bluetootheDevicesListViewDidTappedSesame2(_ sesame2: CHSesame2)
    func newSesameTapped()
    func scanViewTapped()
    func enterTestMode(sesame2: CHSesame2)
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
        let bluetoothDeviceCellViewModel = BluetoothDeviceCellViewModel(sesame2: sesameDevices[indexPath.row])
        bluetoothDeviceCellViewModel.delegate = self
        return bluetoothDeviceCellViewModel
    }
    
    public func didSelectRowAt(_ indexPath: IndexPath) {
        delegate?.bluetootheDevicesListViewDidTappedSesame2(sesameDevices[indexPath.row])
    }

    @objc
    public func loadLocalDevices() {
        self.statusUpdated?(.loading)
        
        CHDeviceManager.shared.getSesame2s() { result in
            switch result {
            case .success(let sesame2s):
                self.sesameDevices = sesame2s
                var keys = [String: Any]()
                for sesame in sesame2s {
                    if let key = sesame.getKey() {
                        keys[sesame.deviceId.uuidString] = key
                    }
                }
                WCSession.default.sendMessage(keys, replyHandler: nil, errorHandler: nil)
//                guard let storeURL = try? CHBleManager.shared.backupStoreURL() else {
//                    return
//                }
//                WCSession.default.transferFile(storeURL, metadata: nil)
                
//                guard let sesame2StoreURL = try? Sesame2Store.shared.backupStoreURL() else {
//                    return
//                }
//                WCSession.default.transferFile(sesame2StoreURL, metadata: nil)
                L.d("Retrieved \(sesame2s.count) devices, sent db to watch.")
                self.statusUpdated?(.received)
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    public func popUpMenuTappedOnItem(_ item: PopUpMenuItem) {
        switch item.type {
        case .addFriends:
            break
        case .addDevices:
            delegate?.newSesameTapped()
        case .receiveKey:
            delegate?.scanViewTapped()
        }
    }
    
    deinit {
//        L.d("BluetoothDevicesListViewModel")
    }
}

// MARK: - Test mode
extension BluetoothDevicesListViewModel: BluetoothDeviceCellViewModelDelegate {
    func enterTestModeTapped(sesame2: CHSesame2) {
        delegate?.enterTestMode(sesame2: sesame2)
    }
    
    func testSwitchToggled(isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: "testMode")
        statusUpdated?(.received)
    }
    
    var isTestModeOn: Bool {
        UserDefaults.standard.bool(forKey: "testMode")
    }
}
