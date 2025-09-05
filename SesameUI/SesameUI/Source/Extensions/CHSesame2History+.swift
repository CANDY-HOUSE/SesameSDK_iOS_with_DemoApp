//
//  CHSesame2History+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension CHSesame2History {
    
    var historyData: CHSesame2HistoryData {
        switch self {
        case .autoLock(let history): return history
        case .bleLock(let history): return history
        case .bleUnlock(let history): return history
        case .wm2Lock(let history): return history
        case .wm2Unlock(let history): return history
        case .webUnlock(let history): return history
        case .webLock(let history): return history
        case .manualElse(let history): return history
        case .manualLocked(let history): return history
        case .manualUnlocked(let history): return history
        case .driveLocked(let history): return history
        case .driveUnlocked(let history): return history
        case .driveFailed(let history): return history
        case .driveClick(let history): return history
        case .manualClick(let history): return history
        case .bleClick(let history): return history
        case .wm2Click(let history): return history
        case .webClick(let history): return history
        case .none(let history): return history
        @unknown default:
            fatalError()
        }
    }
    
    var sortKey: UInt {
        return UInt(historyData.timestamp)
    }
    
    var sectionIdentifier: String {
        historyData.date.toYMD()
    }
    
    var isManualLocked: Bool {
        if case .manualLocked(_) = self {
          return true
        } else {
            return false
        }
    }
    
    var isManualUnlocked: Bool {
        if case .manualUnlocked(_) = self {
          return true
        } else {
            return false
        }
    }

    var isLock: Bool {
        switch self {
        case .bleLock(_), .wm2Lock(_), .autoLock(_), .webLock(_):
            return true
        default:
            return false
        }
    }

    var isUnLock: Bool {
        switch self {
        case .bleUnlock(_), .wm2Unlock(_), .webUnlock(_):
            return true
        default:
            return false
        }
    }

    var isAutoLock: Bool {
        if case .autoLock(_) = self {
          return true
        } else {
            return false
        }
    }

    static func == (lhs: CHSesame2History, rhs: CHSesame2History) -> Bool {
        lhs.sortKey == rhs.sortKey
    }
    
    static func < (lhs: CHSesame2History, rhs: CHSesame2History) -> Bool {
        lhs.sortKey < rhs.sortKey
    }
    static func > (lhs: CHSesame2History, rhs: CHSesame2History) -> Bool {
        lhs.sortKey > rhs.sortKey
    }
}


