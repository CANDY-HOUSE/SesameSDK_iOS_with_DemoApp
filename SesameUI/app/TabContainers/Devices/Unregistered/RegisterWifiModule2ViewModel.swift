//
//  RegisterWifiModule2ViewModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public protocol RegisterWifiModule2ViewModelDelegate: class {
    func registerWifiModule2Succeed()
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
    
    var delegate: RegisterWifiModule2ViewModelDelegate?
    private var wifiModule2s: [CHWifiModule2] = []
    
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
    
    public func didSelectCellAtRow(_ row: Int, ssid: String, password: String) {
        let wifiModule2 = wifiModule2s[row]
        self.password = password
        self.ssid = ssid
        wifiModule2.connect(){_ in}
        
//        switch wifiModule2.deviceStatus {
//        case .readytoRegister:
//            registerSesame2(sesame2)
//            statusUpdated?(.loading)
//        case .dfumode:
//            statusUpdated?(.update(Action.dfu))
//        default:
//            wifiModule2.delegate = self
//            statusUpdated?(.loading)
//        }
    }
    
    deinit {
//        L.d("RegisterWifiModule2ViewModelDelegate")
    }
}

extension RegisterWifiModule2ViewModel: CHBleManagerDelegate {

    public func didDiscoverUnRegisteredWifiModule2s(_ wifiModule2s: [CHWifiModule2]) {
        self.wifiModule2s = wifiModule2s.sorted(by: {
            return $0.rssi!.intValue > $1.rssi!.intValue
        })
        for wifiModule2 in wifiModule2s {
            wifiModule2.delegate = self
        }
        statusUpdated?(.update(nil))
    }
}

extension RegisterWifiModule2ViewModel: CHWifiModule2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if status == .readytoRegister {
//            registerSesame2(device)
        }
    }
    
    func wifiSSID() -> String {
        self.ssid
    }
    
    func wifiPassword() -> String {
        self.password
    }
    
    func wifiSetupResult(_ result: Bool) {
        switch result {
        case true:
            statusUpdated?(.finished(.success(Complete.wifiSetup)))
        case false:
            let error = NSError(domain: "", code: 0, userInfo: ["message": "set up wifi failed"])
            statusUpdated?(.finished(.failure(error)))
        }
    }
}
