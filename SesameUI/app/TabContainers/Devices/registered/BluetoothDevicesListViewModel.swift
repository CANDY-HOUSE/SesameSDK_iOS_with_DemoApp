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
    func registerWifiModule2Tapped()
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
                self.sesameDevices = sesame2s.data
                WatchKitFileTransfer.transferKeysToWatch()
                self.statusUpdated?(.update(nil))
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    public func popUpMenuTappedOnItem(_ item: PopUpMenuItem) {
        switch item.type {
//        case .addFriends:
//            break
        case .addDevices:
            delegate?.newSesameTapped()
        case .receiveKey:
            delegate?.scanViewTapped()
        case .addWifiModule2:
            delegate?.registerWifiModule2Tapped()
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
        CHConfiguration.shared.enableDebugMode(isOn)
        statusUpdated?(.update(nil))
    }
    
    var isTestModeOn: Bool {
        CHConfiguration.shared.isDebugModeEnabled()
    }
}
