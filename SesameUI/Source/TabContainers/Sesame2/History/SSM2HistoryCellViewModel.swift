//
//  SSM2HistoryCellViewModel.swift
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
        switch Sesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case Sesame2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case Sesame2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case Sesame2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case Sesame2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case Sesame2HistoryType.BLE_LOCK:
            return "BLE_LOCK"
        case Sesame2HistoryType.BLE_UNLOCK:
            return "BLE_UNLOCK"
        case Sesame2HistoryType.TIME_CHANGED:
            return "TIME_CHANGED"
        case Sesame2HistoryType.AUTOLOCK_UPDATED:
            return "AUTOLOCK_UPDATED"
        case Sesame2HistoryType.MECH_SETTING_UPDATED:
            return "MECH_SETTING_UPDATED"
        case Sesame2HistoryType.NONE:
            return "NONE"
        }
    }
    
    public var userLabelText: String {
        switch Sesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case Sesame2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case Sesame2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case Sesame2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case Sesame2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case Sesame2HistoryType.BLE_LOCK:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case Sesame2HistoryType.BLE_UNLOCK:
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
        switch Sesame2HistoryType(rawValue: UInt8(history.historyType))! {
        case Sesame2HistoryType.BLE_LOCK,
             Sesame2HistoryType.MANUAL_LOCKED:
            return "icon_lock"
        case Sesame2HistoryType.BLE_UNLOCK,
             Sesame2HistoryType.MANUAL_UNLOCKED:
            return "icon_unlock"
        case Sesame2HistoryType.MANUAL_ELSE:
            return "handmove"
        case Sesame2HistoryType.AUTOLOCK:
            return "autolock"
        case Sesame2HistoryType.MECH_SETTING_UPDATED:
            return "icons_outlined_setting"
        case Sesame2HistoryType.TIME_CHANGED:
            return "iconfinder_9_3898370"
        case Sesame2HistoryType.AUTOLOCK_UPDATED:
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
