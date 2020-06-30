//
//  RegisterDeviceListViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public protocol RegisterDeviceListViewModelDelegate: class {
    func registerSSMSucceed()
}

public final class RegisterDeviceListViewModel: ViewModel {
    private let id = UUID()
//    private var ssmMap = [String: CHSesameBleInterface]()
    private var ssms: [CHSesameBleInterface] = [] {
        didSet {
            for ssm in ssms {
                ssm.connect()
            }
        }
    }
    
    public private(set) var emptyMessage = "No New Devices".localStr
    public private(set) var backButtonImage = "icons_filled_close"
    
    public var statusUpdated: ViewStatusHandler?
    public var delegate: RegisterDeviceListViewModelDelegate?
    
    public init() {
        CHBLEDelegatesManager.shared.addObserver(self)
    }
    
    public var numberOfRows: Int {
        ssms.count
    }
    
    public func registerCellModelForRow(_ row: Int) -> RegisterCellModel {
        RegisterCellModel(ssm: ssms[row])
    }
    
    public func didSelectCellAtRow(_ row: Int) {
        let ssm = ssms[row]
        if ssm.deviceStatus == .readytoRegister {
            registerSSM(ssm)
        } else {
            ssm.delegate = self
        }
        statusUpdated?(.loading)
    }
    
    private func registerSSM(_ ssm: CHSesameBleInterface) {
        
        ssm.registerSesame( { result in
            switch result {

            case .success(_):
                defer {
                    self.statusUpdated?(.received)
                    self.delegate?.registerSSMSucceed()
                    NotificationCenter.default.post(name: .SesameRegistered, object: nil)
                }
                
                L.d("註冊成功", "configureLockPosition")
                var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0)
                ssm.configureLockPosition(configure: &config)
                
                let historyTag = "history test2"
                guard let encodedHistoryTag = historyTag.data(using: .utf8) else {
                    assertionFailure("Encode historyTag failed")
                    return
                }
                L.d("註冊成功", "setHistoryTag", historyTag)
                ssm.setHistoryTag(encodedHistoryTag)
                
            case .failure(let error):
                L.d(ErrorMessage.descriptionFromError(error: error))
                self.statusUpdated?(.finished(.failure(error)))
            }
        })
    }
    
    deinit {
        CHBLEDelegatesManager.shared.removeObserver(self)
    }
}

extension RegisterDeviceListViewModel: CHBleManagerDelegate, CHSesameBleDeviceDelegate {

    public func didDiscoverUnRegisteredSesames(sesames: [CHSesameBleInterface]) {
        ssms = sesames.sorted(by: { $0.rssi.intValue > $1.rssi.intValue })
        statusUpdated?(.received)
    }

//    public func didDiscoverUnRegisteredSesame(sesame: CHSesameBleInterface) {
//        
//    }
    
    public func onBleDeviceStatusChanged(device: CHSesameBleInterface, status: CHDeviceStatus) {
        if status == .readytoRegister {
            registerSSM(device)
        }
    }

}
