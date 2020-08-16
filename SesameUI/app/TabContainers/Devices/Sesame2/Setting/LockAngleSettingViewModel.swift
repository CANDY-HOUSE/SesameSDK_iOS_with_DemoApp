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
    
    var sesame2: CHSesame2
    private let id = UUID()
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0

    public var statusUpdated: ViewStatusHandler?
    
    public private(set) var setLockImage = "icon_lock"
    public private(set) var setUnlockImage = "icon_unlock"
    public private(set) var hintContent = "co.candyhouse.sesame-sdk-test-app.PleaseCompletelyLockUnlock".localized
    public private(set) var title = "co.candyhouse.sesame-sdk-test-app.ConfigureAngles".localized
    public private(set) var hintTitle = "co.candyhouse.sesame-sdk-test-app.PleaseConfigureAngle".localized
    public private(set) var setLockButtonTitle = "co.candyhouse.sesame-sdk-test-app.SetLockedPosition".localized
    public private(set) var setUnlockButtonTitle = "co.candyhouse.sesame-sdk-test-app.SetUnlockedPosition".localized
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
    }
    
    public func viewWillAppear() {
        sesame2.delegate = self
    }
    
    public func setLock() {
        lockDegree = currentDegree
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
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in

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
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            
        }
        statusUpdated?(.finished(.success("")))
    }
    
    public func sesameTapped() {
        sesame2.toggle { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(_):
                strongSelf.statusUpdated?(.update(nil))
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    public func viewDidLoad() {
        if let setting = sesame2.mechSetting {

            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition

            
        } else {
            let error = NSError(domain: "co.candyhouse.sesame-sdk-test-app", code: 0, userInfo: ["message": "Get sesame setting failed."])
            statusUpdated?(.finished(.failure(error)))
        }
        
        guard let status = sesame2.mechStatus else {
            return
        }
        currentDegree = status.position
        statusUpdated?(.update(nil))
    }
}

// MARK: - Delegate
extension LockAngleSettingViewModel: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status) {
        if device.deviceId == sesame2.deviceId,
            status == .receivedBle {
            sesame2.connect(){_ in}
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2,
                                    status: CHSesame2MechStatus,
                                    intention: CHSesame2Intention) {
        guard let status = device.mechStatus else {
            return
        }
        currentDegree = status.position
        statusUpdated?(.update(nil))
    }
}

extension LockAngleSettingViewModel {
    public func sesameViewModel() -> LockViewModel {
        LockViewModel(sesame2: sesame2)
    }
}
