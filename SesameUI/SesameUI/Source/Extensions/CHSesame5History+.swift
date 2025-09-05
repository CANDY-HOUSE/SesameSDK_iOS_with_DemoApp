//
//  CHSesame5History+.swift
//  SesameUI
//  [歷史顯示處理]
//  Created by tse on 2023/4/12.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
extension CHSesame5History {

    var historyData: CHSesame5HistoryData {
        switch self {
        case .autoLock(let history): return history
        case .bleLock(let history): return history
        case .bleUnlock(let history): return history
        case .manualLocked(let history): return history
        case .manualUnlocked(let history): return history
        case .wm2Lock(let history): return history
        case .wm2Unlock(let history): return history
        case .webLock(let history): return history
        case .webUnlock(let history): return history
        case .doorOpen(let history): return history
        case .doorClose(let history): return history
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

    static func < (lhs: CHSesame5History, rhs: CHSesame5History) -> Bool {
        lhs.sortKey < rhs.sortKey
    }
    static func > (lhs: CHSesame5History, rhs: CHSesame5History) -> Bool {
        lhs.sortKey > rhs.sortKey
    }
}
