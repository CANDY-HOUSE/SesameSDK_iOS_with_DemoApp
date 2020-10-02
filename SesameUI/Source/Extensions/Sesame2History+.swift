//
//  Sesame2HistoryMO+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/26.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension Sesame2History {
    
    var avatarImage: String {
        switch self {
        case _ as Sesame2HistoryAutoLock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "autolock"
            } else {
                return (self as! Sesame2HistoryAutoLock).isLocked == true ? "icon_locked" : "autolock"
            }
        case _ as Sesame2HistoryAutoLockUpdated:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryMechSettingUpdated:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryTimeChanged:
            return "iconfinder_9_3898370"
        case _ as Sesame2HistoryLock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "icon_lock"
            } else {
                return (self as! Sesame2HistoryLock).isLocked == true ? "icon_locked" : "icon_lock"
            }
        case _ as Sesame2HistoryManualElse:
            return "handmove"
        case _ as Sesame2HistoryManualLocked:
            return "icon_lock"
        case _ as Sesame2HistoryManualUnlocked:
            return "icon_unlock"
        case _ as Sesame2HistoryUnlock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "icon_unlock"
            } else {
                return (self as! Sesame2HistoryUnlock).isUnlocked == true ? "icon_unlocked" : "icon_unlock"
            }
        case _ as Sesame2HistoryBleAdvParameterUpdated:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryDriveFailed:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryDriveLocked:
            return "icon_locked"
        case _ as Sesame2HistoryDriveUnlocked:
            return "icon_unlocked"
        case _ as Sesame2HistoryNone:
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
        return "\(dateFormatter.string(from: date))"
    }
    
    
    var eventText: String {
        guard CHConfiguration.shared.isDebugModeEnabled() == true else {
            return ""
        }
        return event
    }
    
    private var event: String {
        
        switch self {
        case _ as Sesame2HistoryAutoLock:
            return "AUTOLOCK"
        case _ as Sesame2HistoryAutoLockUpdated:
            return "AUTOLOCK_UPDATED"
        case _ as Sesame2HistoryMechSettingUpdated:
            return "MECH_SETTING_UPDATED"
        case _ as Sesame2HistoryTimeChanged:
            return "TIME_CHANGED"
        case _ as Sesame2HistoryLock:
            return "BLE_LOCK"
        case _ as Sesame2HistoryManualElse:
            return "MANUAL_ELSE"
        case _ as Sesame2HistoryManualLocked:
            return "MANUAL_LOCKED"
        case _ as Sesame2HistoryManualUnlocked:
            return "MANUAL_UNLOCKED"
        case _ as Sesame2HistoryUnlock:
            return "BLE_UNLOCK"
        case _ as Sesame2HistoryBleAdvParameterUpdated:
            return "BLE_ADV_PARAM_UPDATED"
        case _ as Sesame2HistoryDriveFailed:
            return "DRIVE_FAILED"
        case _ as Sesame2HistoryDriveLocked:
            return "DRIVE_LOCKED"
        case _ as Sesame2HistoryDriveUnlocked:
            return "DRIVE_UNLOCKED"
        case _ as Sesame2HistoryNone:
            return "NONE"
        default:
            return ""
        }
    }
    
    var historyTagText: String {
        let displayText = CHConfiguration.shared.isDebugModeEnabled() ? "\(self.recordID): " : ""
        switch self {
        case _ as Sesame2HistoryAutoLock:
            return displayText + "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
        case _ as Sesame2HistoryAutoLockUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as Sesame2HistoryMechSettingUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as Sesame2HistoryTimeChanged:
            return displayText + self.event
        case _ as Sesame2HistoryLock:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as Sesame2HistoryManualElse:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualOperated".localized
        case _ as Sesame2HistoryManualLocked:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualLock".localized
        case _ as Sesame2HistoryManualUnlocked:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualUnlock".localized
        case _ as Sesame2HistoryUnlock:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as Sesame2HistoryBleAdvParameterUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as Sesame2HistoryDriveFailed:
            return displayText + self.event
        case _ as Sesame2HistoryDriveLocked:
            return displayText + self.event
        case _ as Sesame2HistoryDriveUnlocked:
            return displayText + self.event
        case _ as Sesame2HistoryNone:
            return displayText + self.event
        default:
            return ""
        }
    }
    
    var historyDetail: String {
        switch self {
        case _ as Sesame2HistoryLock:
            return ""
        case let autoLockUpdated as Sesame2HistoryAutoLockUpdated:
            return "Enabled? \(autoLockUpdated.enabledBefore) -> \(autoLockUpdated.enabledAfter)"
        case let mechSettingUpdated as Sesame2HistoryMechSettingUpdated:
            return """
            Locked: \(mechSettingUpdated.lockTargetBefore) -> \(mechSettingUpdated.lockTargetAfter), Unlocked: \(mechSettingUpdated.unlockTargetBefore) -> \(mechSettingUpdated.unlockTargetAfter)
            """
        case let historyTimeChanged as Sesame2HistoryTimeChanged:
            return "Time: \(historyTimeChanged.timeBefore) -> \(historyTimeChanged.newTime)"
        case let bleAdvParameterChanged as Sesame2HistoryBleAdvParameterUpdated:
            return "Interval: \(bleAdvParameterChanged.intervalBefore) -> \(bleAdvParameterChanged.intervalAfter), TX Power: \(bleAdvParameterChanged.dbmBefore) -> \(bleAdvParameterChanged.dbmAfter)"
        case let driveFailed as Sesame2HistoryDriveFailed:
            return "fsmRetCode: \(driveFailed.fsmRetCode), stoppedPosition: \(driveFailed.stoppedPosition), device status: \(driveFailed.deviceStatus)"
        default:
            return ""
        }
    }
}
