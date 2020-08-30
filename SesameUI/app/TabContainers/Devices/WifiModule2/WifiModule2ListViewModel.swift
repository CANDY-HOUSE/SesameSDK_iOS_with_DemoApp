//
//  WifiModule2ListViewModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

final class WifiModule2ListViewModel: ViewModel {
    var statusUpdated: ViewStatusHandler?
    
    private var wifiModule2s = [CHWifiModule2]()
    
    init() {
        
    }
    
    func loadLocalDevices() {
        getWifiModule2s()
    }
    
    func getWifiModule2s() {
        CHDeviceManager.shared.getWifiModule2s { result in
            switch result {
            case .success(let wifiModule2s):
                self.wifiModule2s = wifiModule2s.data
                self.statusUpdated?(.update(nil))
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func resetWifiModule2AtIndexPath(_ indexPath: IndexPath) {
        let wifiModeul2 = wifiModule2s[indexPath.row]
        wifiModeul2.reset { result in
            switch result {
            case .success(_):
                self.getWifiModule2s()
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func numberOfRows() -> Int {
        wifiModule2s.count
    }
    
    func cellViewModelAtIndexPath(_ indexPath: IndexPath) -> WifiModule2ListCellModel {
        let wifiModule2 = wifiModule2s[indexPath.row]
        return WifiModule2ListCellModel(wifiModule2: wifiModule2)
    }
}
