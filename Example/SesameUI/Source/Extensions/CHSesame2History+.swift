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
    
    // MARK: - avatarImage
    var avatarImage: String {
        switch self {
        case .autoLock(_):
            return "history_lock"
        case .bleLock(_), .wm2Lock(_), .webLock(_):
            return "history_lock"
        case .bleUnlock(_), .wm2Unlock(_), .webUnlock(_):
            return "history_unlock"
        case .manualElse(_):
            return "handmove"
        case .manualLocked(_):
            return "history_lock"
        case .manualUnlocked(_):
            return "history_unlock"
        case .driveFailed(_):
            return "icons_outlined_setting"
        case .driveLocked(_):
            return "icon_locked"
        case .driveUnlocked(_):
            return "icon_unlocked"
        case .none(_):
            return "icons_outlined_setting"
        default:
            return ""
        }
    }
    
    var dateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss a"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return "\(dateFormatter.string(from: historyData.date))"
    }
    
    var historyTypeImage: String {
        switch self {
        case .autoLock(_):
            return "history_auto"
        case .bleLock(_):
            return "bluetooth"
        case .manualElse(_):
            return ""
        case .manualLocked(_):
            return "history_manul"
        case .manualUnlocked(_):
            return "history_manul"
        case .bleUnlock(_):
            return "bluetooth"
        case .driveFailed(_):
            return ""
        case .driveLocked(_):
            return ""
        case .driveUnlocked(_):
            return ""
        case .none(_):
            return ""
        case .wm2Lock(_):
            return "wifi"
        case .wm2Unlock(_):
            return "wifi"
        case .webLock(_):
            return ""
        case .webUnlock(_):
            return ""
        case .driveClick(_):
            return ""
        case .manualClick(_):
            return ""
        case .bleClick(_):
            return ""
        case .wm2Click(_):
            return ""
        case .webClick(_):
            return ""
        @unknown default:
            return ""
        }
    }
    
    // MARK: - event
    private var event: String {

        switch self {
        case .autoLock(_):
            return "AUTOLOCK"
        case .bleLock(_):
            return "BLE_LOCK"
        case .manualElse(_):
            return "MANUAL_ELSE"
        case .manualLocked(_):
            return "MANUAL_LOCKED"
        case .manualUnlocked(_):
            return "MANUAL_UNLOCKED"
        case .bleUnlock(_):
            return "BLE_UNLOCK"
        case .driveFailed(_):
            return "DRIVE_FAILED"
        case .driveLocked(_):
            return "DRIVE_LOCKED"
        case .driveUnlocked(_):
            return "DRIVE_UNLOCKED"
        case .none(_):
            return "NONE"
        case .wm2Lock(_):
            return "WM2_LOCK"
        case .wm2Unlock(_):
            return "WM2_UNLOCK"
        case .webLock(_):
            return "WEB_LOCK"
        case .webUnlock(_):
            return "WEB_UNLOCK"
        @unknown default:
            return ""
        }
    }
    
    // MARK: - historyTagText
    var historyTagText: String {
        let displayText = ""
        switch self {
        case .autoLock(_):
            return displayText + "co.candyhouse.sesame2.AutoLock".localized
        case .manualElse(_):
            return displayText + "co.candyhouse.sesame2.manualOperated".localized
        case .manualLocked(_):
            return displayText + "co.candyhouse.sesame2.manualLock".localized
        case .manualUnlocked(_):
            return displayText + "co.candyhouse.sesame2.manualUnlock".localized
        case .driveFailed(_),
             .driveLocked(_),
             .driveUnlocked(_),
             .none(_):
            return displayText + self.event
        case .wm2Lock(_),
             .wm2Unlock(_),
             .webLock(_),
             .webUnlock(_),
             .bleLock(_),
             .bleUnlock(_)
            :
            if let historyTag = self.historyData.historyTag {
                L.d("標籤1", historyTag)
                return displayText + parseHistoryTag(historyTag)
            } else {
                L.d("標籤2", self.historyData.historyTag)
                return displayText + self.event
            }
        @unknown default:
            return ""
        }
    }

    func parseHistoryTag(_ historyTag: Data) -> String {
        return String(decoding: historyTag, as: UTF8.self)
    }
}


