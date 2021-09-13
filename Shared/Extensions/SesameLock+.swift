//
//  SesameLock+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/02/05.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
import UIKit.UIColor
#else
import SesameWatchKitSDK
import WatchKit
#endif

extension CHSesameLock {
    func getShadowStatus() -> CHSesame2ShadowStatus? {
        if let sesameLock = self as? CHSesame2 {
            return sesameLock.deviceShadowStatus
        } else if let sesameLock = self as? CHSesameBot {
            return sesameLock.deviceShadowStatus
        } else if let sesameLock = self as? CHSesameBike {
            return sesameLock.deviceShadowStatus
        } else {
            return nil
        }
    }
}
