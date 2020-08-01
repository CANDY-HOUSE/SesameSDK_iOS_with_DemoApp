//
//  LockViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class LockViewModel: ViewModel {

    private var sesame2: CHSesame2
    public var statusUpdated: ViewStatusHandler?
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
    }
    
    public func currentDegree() -> Float? {
        guard let status = sesame2.mechStatus else {
            return nil
        }
        return angle2degree(angle: status.position)
    }
    
    public func lockPositions() -> (lockPosition: Float?, unlockPosition: Float?) {
        guard let setting = sesame2.mechSetting else {
                return (nil, nil)
        }
        return (angle2degree(angle: setting.lockPosition),
                angle2degree(angle: setting.unlockPosition))
    }
    
    deinit {
        L.d("LockViewModel deinit")
    }
}
