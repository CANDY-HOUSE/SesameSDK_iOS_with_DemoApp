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

    private var ssm: CHSesameBleInterface
    public var statusUpdated: ViewStatusHandler?
    
    init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
    }
    
    public func currentDegree() -> Float? {
        guard let status = ssm.mechStatus,
            let currentAngle = status.getPosition() else {
            return nil
        }
        return angle2degree(angle: Int16(currentAngle))
    }
    
    public func lockPositions() -> (lockPosition: Float?, unlockPosition: Float?) {
        guard let setting = ssm.mechSetting,
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
