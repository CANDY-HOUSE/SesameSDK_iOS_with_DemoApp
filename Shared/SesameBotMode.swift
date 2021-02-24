//
//  SesameBotMode.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/28.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

enum SesameBotClickMode: Int, CaseIterable {
    case normal
    case circle
    case longPress
    
    func next() -> SesameBotClickMode {
        return SesameBotClickMode(rawValue: rawValue+1) ?? .normal
    }
    
    func desc() -> String {
        switch self {
        case .normal: return "co.candyhouse.sesame2.sesameBotModeNormal".localized
        case .circle: return "co.candyhouse.sesame2.sesameBotModeCircle".localized
        case .longPress: return "co.candyhouse.sesame2.sesameBotModeLongPress".localized
        }
    }
    
    static func modeForSesameBot(_ sesameBot: CHSesameBot) -> SesameBotClickMode? {
        guard let mechSetting = sesameBot.mechSetting else {
            return nil
        }
        
        if mechSetting.lockSecConfig.clickLockSeconds == UInt8(20.0) {
            return .circle
        } else if mechSetting.lockSecConfig.clickHoldSeconds == UInt8(20.0) {
            return .longPress
        } else {
            return .normal
        }
    }
}
