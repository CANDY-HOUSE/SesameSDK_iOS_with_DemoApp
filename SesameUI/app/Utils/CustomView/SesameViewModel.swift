//
//  SesameViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class SesameViewModel: ViewModel {

    private var sesame2: CHSesame2
    public var statusUpdated: ViewStatusHandler?
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
    }
    
    public func currentDegree() -> Float? {
        guard let status = sesame2.mechStatus,
            let currentAngle = status.getPosition() else {
            return nil
        }
        return angle2degree(angle: Int16(currentAngle))
    }
    
    public func lockPositions() -> (lockPosition: Float?, unlockPosition: Float?) {
        guard let setting = sesame2.mechSetting,
            let lockDegree = setting.getLockPosition(),
            let unlockDegree = setting.getUnlockPosition() else {
                return (nil, nil)
        }
        return (angle2degree(angle: Int16(lockDegree)),
                angle2degree(angle: Int16(unlockDegree)))
    }
    
    deinit {
        L.d("SesameViewModel deinit")
    }
}
