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
    
    var ssm: CHSesame2
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
    
    init(ssm: CHSesame2) {
        self.ssm = ssm
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
//        var config = CHSesameLockPositionConfiguration(lockTarget: lockDegree, unlockTarget: unlockDegree)
        if abs(lockDegree - unlockDegree) < 50 {
            statusUpdated?(.finished(.failure(LockAngleError.tooClose)))
            return
        }
        ssm.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in

         }
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

        if abs(lockDegree - unlockDegree) < 50 {
            statusUpdated?(.finished(.failure(LockAngleError.tooClose)))
            return
        }
          ssm.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in

         }
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
            
            if !setting.isConfigured() {
//                var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0){res in}
                ssm.configureLockPosition(lockTarget: 1024/4, unlockTarget: 0){res in}
            }
            
        } else {
            let error = NSError(domain: "co.candyhouse.sesame-sdk-test-app", code: 0, userInfo: ["Description": "Get sesame setting failed."])
            statusUpdated?(.finished(.failure(error)))
        }
        
        guard let status = ssm.mechStatus else {
            return
        }
        currentDegree = Int16(status.getPosition()!)
        statusUpdated?(.received)
    }
}

// MARK: - Delegate
extension LockAngleSettingViewModel: CHSesameDelegate {
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHDeviceStatus) {
        if device.deviceId == ssm.deviceId,
            status == .receiveBle {
            ssm.connect()
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2,
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
