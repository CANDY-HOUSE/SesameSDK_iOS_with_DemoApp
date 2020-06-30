//
//  LockAngleSettingViewModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/6/20.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class LockAngleSettingViewModel: ViewModel {
    enum LockAngleError: Error {
        case tooClose
    }
    
    var ssm: CHSesameBleInterface
    private let id = UUID()
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0

    public var statusUpdated: ViewStatusHandler?
    
    public private(set) var setLockImage = "icon_lock"
    public private(set) var setUnlockImage = "icon_unlock"
    public private(set) var hintContent = "Please completely lock/unlock Sesame, and press the buttons below to configure locked/unlocked positions respectively.".localStr
    public private(set) var title = "Configure Angles".localStr
    public private(set) var hintTitle = "Please configure Locked/Unlocked Angle.".localStr
    public private(set) var setLockButtonTitle = "Set Locked Position".localStr
    public private(set) var setUnlockButtonTitle = "Set Unlocked Position".localStr
    
    init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
//        ssm.updateObserver(self)
//        ssm.updateObserver(self, forKey: id.uuidString)

    }
    
    public func viewWillAppear() {
        ssm.delegate = self
    }
    
    public func setLock() {
        lockDegree = currentDegree
        if lockDegree == -32768 {
            lockDegree = 0
        }
        if unlockDegree == -32768 {
            unlockDegree = 0
        }
        var config = CHSesameLockPositionConfiguration(lockTarget: lockDegree, unlockTarget: unlockDegree)
        if abs(lockDegree - unlockDegree) < 50 {
            statusUpdated?(.finished(.failure(LockAngleError.tooClose)))
            return
        }
        ssm.configureLockPosition(configure: &config)
        statusUpdated?(.finished(.success("")))
    }
    
    public func setUnlock() {
        unlockDegree = currentDegree
        if lockDegree == -32768 {
            lockDegree = 0
        }
        if unlockDegree == -32768 {
            unlockDegree = 0
        }

        var config = CHSesameLockPositionConfiguration(lockTarget: lockDegree, unlockTarget: unlockDegree)
        if abs(lockDegree - unlockDegree) < 50 {
            statusUpdated?(.finished(.failure(LockAngleError.tooClose)))
            return
        }
        ssm.configureLockPosition(configure: &config)
        statusUpdated?(.finished(.success("")))
    }
    
    public func sesameTapped() {
        ssm.toggle { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(_):
                strongSelf.statusUpdated?(.received)
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    public func viewDidLoad() {
        if let setting = ssm.mechSetting {

            lockDegree = Int16(setting.getLockPosition()!)
            unlockDegree = Int16(setting.getUnlockPosition()!)
            
            if setting.isConfigured() {
                L.d("已經設定過")
            } else {
                L.d("沒設定過")
                var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0)
                ssm.configureLockPosition(configure: &config)
            }
        } else {
            L.d("設定讀取失敗")
        }
        
        guard let status = ssm.mechStatus else {
            return
        }
        currentDegree = Int16(status.getPosition()!)
        statusUpdated?(.received)
    }
}

// MARK: - Delegate
extension LockAngleSettingViewModel: CHSesameBleDeviceDelegate {
    public func onBleDeviceStatusChanged(device: CHSesameBleInterface,
                                         status: CHDeviceStatus) {
        if device.deviceId == ssm.deviceId,
            status == .receiveBle {
            ssm.connect()
        }
//        statusUpdated?(.received)
    }
    
    public func onMechStatusChanged(device: CHSesameBleInterface,
                                    status: CHSesameMechStatus,
                                    intention: CHSesameIntention) {
        guard let status = device.mechStatus else {
            return
        }
        currentDegree = Int16(status.getPosition()!)
        statusUpdated?(.received)
    }
}

extension LockAngleSettingViewModel {
    public func sesameViewModel() -> SesameViewModel {
        SesameViewModel(ssm: ssm)
    }
}
