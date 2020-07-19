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
    func registerSesame2Succeed()
}

public final class RegisterDeviceListViewModel: ViewModel {
    private let id = UUID()

    private var sesame2s: [CHSesame2] = [] {
        didSet {
            for sesame in sesame2s {
                sesame.connect(){_ in}
            }
        }
    }
    var sesame2Versions = [String:String]()
    
    private var dfuHelper: DFUHelper?
    
    public private(set) var emptyMessage = "No New Devices".localStr
    public private(set) var backButtonImage = "icons_filled_close"
    private(set) var mySesameText = "ドラえもん".localStr
    private(set) var dfuActionText = "DFU".localStr
    
    public var statusUpdated: ViewStatusHandler?
    public var delegate: RegisterDeviceListViewModelDelegate?
    
    public init() {
        CHBLEDelegatesManager.shared.addObserver(self)
    }
    
    public var numberOfRows: Int {
        sesame2s.count
    }
    
    public func registerCellModelForRow(_ row: Int) -> RegisterCellModel {
        RegisterCellModel(sesame2: sesame2s[row])
    }
    
    public func didSelectCellAtRow(_ row: Int) {
        let sesame2 = sesame2s[row]
        if sesame2.deviceStatus == .readytoRegister {
            registerSesame2(sesame2)
        } else {
            sesame2.delegate = self
        }
        statusUpdated?(.loading)
    }
    
    private func registerSesame2(_ sesame2: CHSesame2) {
        
        sesame2.registerSesame( { result in
            switch result {

            case .success(_):
                defer {
                    self.statusUpdated?(.received)
                    self.delegate?.registerSesame2Succeed()
                }
                
                L.d("註冊成功", "configureLockPosition")
                
                guard let encodedHistoryTag = self.mySesameText.data(using: .utf8) else {
                    assertionFailure("Encode historyTag failed")
                    return
                }
                
                L.d("註冊成功", "setHistoryTag", self.mySesameText)
                
                sesame2.setHistoryTag(encodedHistoryTag) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        self.statusUpdated?(.finished(.failure(error)))
                    }
                }
                
                sesame2.configureLockPosition(lockTarget: 1024/4, unlockTarget: 0){ result in
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
    
    func dfuDeviceAtIndexPath(_ indexPath: IndexPath, observer: DFUHelperObserver) {
        let sesam32 = sesame2s[indexPath.row]
        sesame2Versions.removeValue(forKey: sesam32.deviceId.uuidString)
        guard let filePath = Constant
            .resourceBundle
            .url(forResource: nil,
                 withExtension: ".zip"),
            let zipData = try? Data(contentsOf: filePath) else {
                return
        }
        
        sesam32.updateFirmware { result in
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    L.d("Request commad failed.")
                    return
                }
                L.d("Success.")
                self.dfuHelper = CHDFUHelper(peripheral: peripheral, zipData: zipData)
                self.dfuHelper?.observer = observer
                self.dfuHelper?.start()
            case .failure(let error):
                L.d(error.errorDescription())
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func cancelDFU() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    func viewDidDisappear() {
        cancelDFU()
    }
    
    private func getFirmwareVersionForDeviceAtIndexPath(_ indexPath: IndexPath) {
        let sesame2 = sesame2s[indexPath.row]
        sesame2.getVersionTag { result in
            switch result {
            case .success(let versionResult):
                self.sesame2Versions[sesame2.deviceId.uuidString] = versionResult.data
                self.statusUpdated?(.received)
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func firmwareVersionForDeviceAtIndexPath(_ indexPath: IndexPath) -> String {
        let sesame2 = sesame2s[indexPath.row]
        if let version = sesame2Versions[sesame2.deviceId.uuidString] {
            return version
        }
        getFirmwareVersionForDeviceAtIndexPath(indexPath)
        return ""
    }
    
    deinit {
        CHBLEDelegatesManager.shared.removeObserver(self)
    }
}

extension RegisterDeviceListViewModel: CHBleManagerDelegate, CHSesame2Delegate {

    public func didDiscoverUnRegisteredSesames(sesames: [CHSesame2]) {
        sesame2s = sesames.sorted(by: { $0.rssi.intValue > $1.rssi.intValue })
        statusUpdated?(.received)
    }

    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if status == .readytoRegister {
            registerSesame2(device)
        }
    }

}
