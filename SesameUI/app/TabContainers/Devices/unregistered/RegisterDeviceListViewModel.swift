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
    private var ssms: [CHSesame2] = [] {
        didSet {
            for ssm in ssms {
                ssm.connect()
            }
        }
    }
    
    public private(set) var emptyMessage = "No New Devices".localStr
    public private(set) var backButtonImage = "icons_filled_close"
    private(set) var mySesameText = "My Sesame".localStr
    
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
    
    private func registerSSM(_ ssm: CHSesame2) {
        
        ssm.registerSesame( { result in
            switch result {

            case .success(_):
                defer {
                    self.statusUpdated?(.received)
                    self.delegate?.registerSSMSucceed()
                }
                
                L.d("註冊成功", "configureLockPosition")
//                var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0)
                ssm.configureLockPosition(lockTarget: 1024/4, unlockTarget: 0){ result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        self.statusUpdated?(.finished(.failure(error)))
                    }
                }

                guard let encodedHistoryTag = self.mySesameText.data(using: .utf8) else {
                    assertionFailure("Encode historyTag failed")
                    return
                }
                L.d("註冊成功", "setHistoryTag", self.mySesameText)
                ssm.setHistoryTag(encodedHistoryTag) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        self.statusUpdated?(.finished(.failure(error)))
                    }
                }
                
            case .failure(let error):
                L.d(error.errorDescription())
                self.statusUpdated?(.finished(.failure(error)))
            }
        })
    }
    
    deinit {
        CHBLEDelegatesManager.shared.removeObserver(self)
    }
}

extension RegisterDeviceListViewModel: CHBleManagerDelegate, CHSesameDelegate {

    public func didDiscoverUnRegisteredSesames(sesames: [CHSesame2]) {
        ssms = sesames.sorted(by: { $0.rssi.intValue > $1.rssi.intValue })
        statusUpdated?(.received)
    }

    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHDeviceStatus) {
        if status == .readytoRegister {
            registerSSM(device)
        }
    }

}
