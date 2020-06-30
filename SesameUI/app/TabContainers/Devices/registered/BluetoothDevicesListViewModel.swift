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
    func bluetootheDevicesListViewDidTappedSSM(_ ssm: CHSesameBleInterface)
    func newSesameTapped()
    func scanViewTapped()
    func enterTestMode(ssm: CHSesameBleInterface)
}

final class BluetoothDevicesListViewModel: ViewModel {
    var coordinator: BluetoothDevicesListCoordinator
    weak var delegate: BluetoothDevicesListViewModelDelegate?
    
//    private var sesameDevicesMap: [String: CHSesameBleInterface] = [:]
    private var sesameDevices: [CHSesameBleInterface] = []
//    private var sesameDeviceCellMap: [Int: BluetoothDeviceCellViewModel] = [:]
    
    public var statusUpdated: ViewStatusHandler?
    
    init(coordinator: BluetoothDevicesListCoordinator) {
        self.coordinator = coordinator
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(loadLocalDevices),
                         name: .SesameDeleted,
                         object: nil)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(loadLocalDevices),
                         name: .SesameRegistered,
                         object: nil)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(loadLocalDevices),
                         name: .SesamePropertyChanged,
                         object: nil)
        
    }
    
//    private var sesameDevices: [CHSesameBleInterface] {
//        sesameDevicesMap.map {
//            $0.value
//        }
//        .sorted(by: {
//            let name1 = SSMStore.shared.getPropertyForDevice($0)?.name ?? $0.deviceId.uuidString
//            let name2 = SSMStore.shared.getPropertyForDevice($1)?.name ?? $1.deviceId.uuidString
//            return name1 < name2
//        })
//    }


    public var numberOfRows: Int {
        return sesameDevices.count
    }
    
    public func cellViewModelAt(_ indexPath: IndexPath) -> BluetoothDeviceCellViewModel {
//        if let viewModel = sesameDeviceCellMap[indexPath.row] {
//            return viewModel
//        } else {
            let bluetoothDeviceCellViewModel = BluetoothDeviceCellViewModel(ssm: sesameDevices[indexPath.row])
            bluetoothDeviceCellViewModel.delegate = self
//            sesameDeviceCellMap[indexPath.row] = bluetoothDeviceCellViewModel
            return bluetoothDeviceCellViewModel
//        }
    }
    
    public func didSelectRowAt(_ indexPath: IndexPath) {
        L.d("didSelectRowAt" , indexPath,delegate)
        delegate?.bluetootheDevicesListViewDidTappedSSM(sesameDevices[indexPath.row])
    }

    @objc
    public func loadLocalDevices() {
        self.statusUpdated?(.loading)
//        self.sesameDevicesMap.removeAll()
//        self.sesameDeviceCellMap.removeAll()
        
        CHBleManager.shared.getMyDevices() { result in
            switch result {
            case .success(let devices):
                self.sesameDevices = devices
                L.d("Retrieved \(devices.count) devices.")
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
}

// MARK: - Test mode
extension BluetoothDevicesListViewModel: BluetoothDeviceCellViewModelDelegate {
    func enterTestModeTapped(ssm: CHSesameBleInterface) {
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
