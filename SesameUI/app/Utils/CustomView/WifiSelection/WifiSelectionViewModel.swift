//
//  WifiSelectionViewModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import CoreLocation
import SesameSDK

protocol WifiSelectionTableViewModelDelegate: class {
    func didSelectedWifi(_ wifi: Wifi)
}

final class WifiSelectionTableViewModel: ViewModel {
    var statusUpdated: ViewStatusHandler?
    var wifis = [Wifi]()
    let wifiModule2: CHWifiModule2
    var delegate: WifiSelectionTableViewModelDelegate?
    
    init(wifiModule2: CHWifiModule2) {
        self.wifiModule2 = wifiModule2
        self.wifiModule2.delegate = self
        self.wifiModule2.connect { [weak self] result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                self?.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func numberOfRows() -> Int {
        wifis.count
    }
    
    func cellViewModelAtIndexPath(_ indexPath: IndexPath) -> WifiSelectionTableViewCellModel {
        return WifiSelectionTableViewCellModel(wifi: wifis[indexPath.row])
    }
    
    func ssidForIndexPath(_ indexPath: IndexPath) -> String? {
        let wifi = wifis[indexPath.row]
        return wifi.wifiInformation.ssidName()
    }
    
    func didSelectRowAtIndexPath(_ indexPath: IndexPath, password: String) {
        self.wifiModule2.disableWifiDiscovery { _ in
            
        }
        
        var wifi = wifis[indexPath.row]
        wifi.password = password
        delegate?.didSelectedWifi(wifi)
    }
    
    deinit {
        L.d("WifiSelectionTableViewModel deinit")
        self.wifiModule2.disableWifiDiscovery { _ in
            
        }
    }
}

extension WifiSelectionTableViewModel: CHWifiModule2Delegate {
    func onBleDeviceStatusChanged(device: CHWifiModule2, status: CHWifiModule2Status) {
        if status == .readyToSetup {
            statusUpdated?(.loading)
            device.enableWifiDiscovery { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let content):
                    let wifi = Wifi(id: UUID(),
                                    password: nil,
                                    wifiInformation: content.data)
                    let ssids = strongSelf.wifis.compactMap { wifi -> String? in
                        return wifi.wifiInformation.ssidName()
                    }
                    guard let ssidName = wifi.wifiInformation.ssidName() else {
                        return
                    }
                    if !ssids.contains(ssidName) {
                        strongSelf.wifis.append(wifi)
                        strongSelf.wifis.sort { left, right -> Bool in
                            left.wifiInformation.rssi > right.wifiInformation.rssi
                        }
                        strongSelf.statusUpdated?(.update(nil))
                    }
                case .failure(let error):
                    L.d(error)
                }
            }
        }
    }
}

final class WifiSelectionTableViewCellModel: ViewModel {
    var statusUpdated: ViewStatusHandler?
    private var wifi: Wifi
    
    lazy private(set) var ssid: String? = {
        wifi.wifiInformation.ssidName()
    }()
    
    lazy private(set) var rssi: Int = {
        Int(wifi.wifiInformation.rssi)
    }()
    
    func distanceInCentermiter() -> String {
        let distance = pow(10.0, ((Double(4) - Double(rssi)) - 62.0) / 20.0)
        return String(Int(distance * 100))
    }
    
    init(wifi: Wifi) {
        self.wifi = wifi
    }
}
