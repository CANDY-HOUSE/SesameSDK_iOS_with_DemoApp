//
//  RegisterWifiModule2ViewModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

protocol RegisterWifiModule2ViewModelDelegate: class {
    func registerWifiModule2Succeed()
    func didSelectedWifiModule2(_ wifiModule2: CHWifiModule2)
    func didSelectedWifi(_ wifiNotify: @escaping (Wifi)->Void)
}

final class RegisterWifiModule2ViewModel: ViewModel {
    enum Action {
        case dfu
    }
    
    enum Complete {
        case wifiSetup
    }
    
    private var password = ""
    private var ssid = ""
    
    public private(set) var emptyMessage = "co.candyhouse.sesame-sdk-test-app.NoNewDevices".localized
    
    var delegate: RegisterWifiModule2ViewModelDelegate? {
        didSet {
            if delegate != nil {
                delegate?.didSelectedWifi({ [weak self] wifi in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.registerWifiModule2WithWifi(wifi)
                })
            }
        }
    }
    private var wifiModule2s: [CHWifiModule2] = []
    private var selectedIndex: Int?
    
    public var statusUpdated: ViewStatusHandler?
    
    public init() {
        CHBLEDelegatesManager.shared.addObserver(self)
    }
    
    public var numberOfSections: Int {
        1
    }

    public func numberOfRowsInSection(_ section: Int) -> Int {
        wifiModule2s.count
    }
    
    public func cellViewModelForRowAtIndexPath(_ indexPath: IndexPath) -> RegisterWifiModule2CellModel {
        RegisterWifiModule2CellModel(wifiModule2: wifiModule2s[indexPath.row])
    }
    
    public func didSelectCellAtIndexPath(_ indexPath: IndexPath) {
        let wifiModule2 = wifiModule2s[indexPath.row]
        selectedIndex = indexPath.row
        delegate?.didSelectedWifiModule2(wifiModule2)
    }
    
    func registerWifiModule2WithWifi(_ wifi: Wifi) {
        guard let selectedIndex = selectedIndex else {
            return
        }
        let wifiModule2 = wifiModule2s[selectedIndex]
        statusUpdated?(.loading)
        
        wifiModule2.delegate = self
        wifiModule2.connect(result: { [weak self, unowned wifiModule2] _ in
            self?.registerWifiModule2(wifiModule2, wifi: wifi)
        })
    }
    
    func registerWifiModule2(_ wifiModule2: CHWifiModule2, wifi: Wifi) {
        wifiModule2.register { [unowned wifiModule2, weak self] result in
            switch result {
            case .success(_):
                self?.setupWifiCredential(wifiModule2: wifiModule2, wifi: wifi)
            case .failure(let error):
                self?.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func setupWifiCredential(wifiModule2: CHWifiModule2, wifi: Wifi) {
        wifiModule2.sendWifiCredential(ssid: wifi.wifiInformation.ssidName()!,
                                       password: wifi.password!) { [weak self] result in
            switch result {
            case .success(_):
//                WM2 connected to AP, waiting WM2 connect to AWSIoT
                break
            case .failure(let error):
                self?.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func updateSesame2ToWifiModule2Shadow(_ device: CHWifiModule2) {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                device.updateSesame2s(sesame2s.data) { [weak self] result in
                    switch result {
                    case .success(_):
                        self?.disconnect()
                        DispatchQueue.main.async {
                            self?.delegate?.registerWifiModule2Succeed()
                        }
                    case .failure(let error):
                        self?.statusUpdated?(.finished(.failure(error)))
                    }
                }
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func disconnect() {
        for wifiModule2 in wifiModule2s {
            wifiModule2.disconnect { _ in
                
            }
        }
    }
    
    deinit {
        CHBLEDelegatesManager.shared.removeObserver(self)
    }
}

extension RegisterWifiModule2ViewModel: CHBleManagerDelegate {

    public func didDiscoverUnRegisteredWifiModule2s(_ wifiModule2s: [CHWifiModule2]) {
        self.wifiModule2s = wifiModule2s.sorted(by: {
            return $0.rssi!.intValue > $1.rssi!.intValue
        })
        statusUpdated?(.update(nil))
    }
}

extension RegisterWifiModule2ViewModel: CHWifiModule2Delegate {
    public func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHWifiModule2Status) {
        if status == .connected {
            updateSesame2ToWifiModule2Shadow(device)
        }
    }
}
