//
//  Sesame2HistoryCellViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import CoreData

public final class Sesame2HistoryCellViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    
    let history: Sesame2HistoryMO
    
    init(history: Sesame2HistoryMO) {
        self.history = history
    }
    
    public func timeLabelText() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(history.timeStamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss a"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return "\(dateFormatter.string(from: date))"
    }
    
    public var eventImage: String {
        ""
    }
    
    public var historyEvent: String {
        switch CHSesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case CHSesame2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case CHSesame2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case CHSesame2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case CHSesame2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case CHSesame2HistoryType.BLE_LOCK:
            return "BLE_LOCK"
        case CHSesame2HistoryType.BLE_UNLOCK:
            return "BLE_UNLOCK"
        case CHSesame2HistoryType.TIME_CHANGED:
            return "TIME_CHANGED"
        case CHSesame2HistoryType.AUTOLOCK_UPDATED:
            return "AUTOLOCK_UPDATED"
        case CHSesame2HistoryType.MECH_SETTING_UPDATED:
            return "MECH_SETTING_UPDATED"
        case CHSesame2HistoryType.NONE:
            return "NONE"
        }
    }
    
    public var userLabelText: String {
        switch CHSesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case CHSesame2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case CHSesame2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case CHSesame2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case CHSesame2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case CHSesame2HistoryType.BLE_LOCK:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case CHSesame2HistoryType.BLE_UNLOCK:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        default:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        }
    }

    public var avatarImage: String {
        switch CHSesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case CHSesame2HistoryType.BLE_LOCK,
             CHSesame2HistoryType.MANUAL_LOCKED:
            return "icon_lock"
        case CHSesame2HistoryType.BLE_UNLOCK,
             CHSesame2HistoryType.MANUAL_UNLOCKED:
            return "icon_unlock"
        case CHSesame2HistoryType.MANUAL_ELSE:
            return "handmove"
        case CHSesame2HistoryType.AUTOLOCK:
            return "autolock"
        case CHSesame2HistoryType.MECH_SETTING_UPDATED:
            return "icons_outlined_setting"
        case CHSesame2HistoryType.TIME_CHANGED:
            return "iconfinder_9_3898370"
        case CHSesame2HistoryType.AUTOLOCK_UPDATED:
            return "icons_outlined_setting"
        default:
            return ""
        }
    }
    
    func information() -> String {
        switch history {
        case _ as Sesame2HistoryLockUnlockMO:
            return ""
        case let autoLockUpdated as Sesame2HistoryAutoLockUpdatedMO:
            return "Enabled? \(autoLockUpdated.enabledBefore) -> \(autoLockUpdated.enabledAfter)"
        case let mechSettingUpdated as Sesame2HistoryMechSettingUpdatedMO:
            return """
            Locked: \(mechSettingUpdated.lockTargetBefore) -> \(mechSettingUpdated.lockTargetAfter), Unlocked: \(mechSettingUpdated.unlockTargetBefore) -> \(mechSettingUpdated.unlockTargetAfter)
            """
        case let historyTimeChanged as Sesame2HistoryTimeChangedMO:
            if let newTime = historyTimeChanged.newTime,
                let timeBefore = historyTimeChanged.timeBefore {
                return "Time: \(timeBefore) -> \(newTime)"
            } else {
                return ""
            }
        default:
            return ""
        }
    }
}
