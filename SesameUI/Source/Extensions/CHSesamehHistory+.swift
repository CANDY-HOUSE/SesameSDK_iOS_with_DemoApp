//
//  CHSwitchHistory+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

//extension CHSesameBotHistory {
//    private static var _isUnlocked = [String:Bool]()
//    private static var _isLocked = [String:Bool]()
//    
//    var isUnlocked: Bool {
//        get {
//            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
//            return CHSesameBotHistory._isUnlocked[tmpAddress] ?? false
//        }
//        set(newValue) {
//            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
//            CHSesameBotHistory._isUnlocked[tmpAddress] = newValue
//        }
//    }
//    
//    var isLocked: Bool {
//        get {
//            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
//            return CHSesameBotHistory._isLocked[tmpAddress] ?? false
//        }
//        set(newValue) {
//            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
//            CHSesameBotHistory._isLocked[tmpAddress] = newValue
//        }
//    }
//    
//    var historyData: CHSwitchHistoryData {
//        switch self {
//        case .autoLock(let autoLockHistory):
//            return autoLockHistory
//        case .autoLockUpdated(let autoLockUpdatedHistory):
//            return autoLockUpdatedHistory
//        case .mechSettingUpdated(let mechSettingUpdatedHistory):
//            return mechSettingUpdatedHistory
//        case .timeChanged(let timeChaedHistoryHistory):
//            return timeChaedHistoryHistory
//        case .bleLock(let lockHistory):
//            return lockHistory
//        case .manualElse(let manualElseHisotry):
//            return manualElseHisotry
//        case .manualLocked(let manualLockedHistory):
//            return manualLockedHistory
//        case .manualUnlocked(let manualUnlockedHistory):
//            return manualUnlockedHistory
//        case .bleUnLock(let bleUnLockHistory):
//            return bleUnLockHistory
//        case .bleAdvParameterUpdated(let bleAdvUpdatedHistory):
//            return bleAdvUpdatedHistory
//        case .driveLocked(let driveLockHistory):
//            return driveLockHistory
//        case .driveUnlocked(let driveUnlockedHistory):
//            return driveUnlockedHistory
//        case .driveFailed(let driveFailedHistory):
//            return driveFailedHistory
//        case .blePositioning(let blePostingHistory):
//            return blePostingHistory
//        case .drivePosition(let drivePositionHistory):
//            return drivePositionHistory
//        case .none(let noneHistory):
//            return noneHistory
//        @unknown default:
//            fatalError()
//        }
//    }
//    
//    var sortKey: UInt {
//        return UInt(historyData.timestamp)
//    }
//    
//    var date: Date {
//        historyData.date
//    }
//    
//    var sectionIdentifier: String {
//        date.toYMD()
//    }
//    
//    func isManualElse() -> Bool {
//        if case .manualElse(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isManualUnlocked: Bool {
//        if case .manualUnlocked(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isManulElse: Bool {
//        if case .manualElse(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isBleLock: Bool {
//        if case .bleLock(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isBleUnLock: Bool {
//        if case .bleUnLock(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isAutoLock: Bool {
//        if case .autoLock(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isAutoLockUpdated: Bool {
//        if case .autoLockUpdated(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isMechSettingUpdated: Bool {
//        if case .mechSettingUpdated(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isTimeChanged: Bool {
//        if case .timeChanged(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isBleAdvParameterUpdated: Bool {
//        if case .bleAdvParameterUpdated(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isDriveLocked: Bool {
//        if case .driveLocked(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isDriveUnlocked: Bool {
//        if case .driveUnlocked(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isDriveFailed: Bool {
//        if case .driveFailed(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//    
//    var isNone: Bool {
//        if case .none(_) = self {
//          return true
//        } else {
//            return false
//        }
//    }
//
//    static func == (lhs: CHSesameBotHistory, rhs: CHSesameBotHistory) -> Bool {
//        lhs.sortKey == rhs.sortKey
//    }
//    
//    static func < (lhs: CHSesameBotHistory, rhs: CHSesameBotHistory) -> Bool {
//        lhs.sortKey < rhs.sortKey
//    }
//    
//    // MARK: - avatarImage
//    var avatarImage: String {
//        switch self {
//        case .autoLock(_):
//            return self.isLocked == true ? "icon_locked" : "autolock"
//        case .autoLockUpdated(_):
//            return "icons_outlined_setting"
//        case .mechSettingUpdated(_):
//            return "icons_outlined_setting"
//        case .timeChanged(_):
//            return "iconfinder_9_3898370"
//        case .bleLock(_):
//            return self.isLocked == true ? "icon_locked" : "icon_lock"
//        case .manualElse(_):
//            return "handmove"
//        case .manualLocked(_):
//            return "icon_lock"
//        case .manualUnlocked(_):
//            return "icon_unlock"
//        case .bleUnLock(_):
//            return self.isUnlocked == true ? "icon_unlocked" : "icon_unlock"
//        case .bleAdvParameterUpdated(_):
//            return "icons_outlined_setting"
//        case .driveFailed(_):
//            return "icons_outlined_setting"
//        case .driveLocked(_):
//            return "icon_locked"
//        case .driveUnlocked(_):
//            return "icon_unlocked"
//        case .none(_):
//            return "icons_outlined_setting"
//        
//        case .blePositioning(_):
//            return "icons_outlined_setting"
//        case .drivePosition(_):
//            return "icons_outlined_setting"
//        @unknown default:
//            return ""
//        }
//    }
//    
//    var dateTime: String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm:ss a"
//        dateFormatter.locale = Locale(identifier: "ja_JP")
//        dateFormatter.amSymbol = "AM"
//        dateFormatter.pmSymbol = "PM"
//        return "\(dateFormatter.string(from: date))"
//    }
//    
//    
//    var eventText: String {
//        return ""
//    }
//    
//    // MARK: - event
//    private var event: String {
//        
//        switch self {
//        case .autoLock(_):
//            return "AUTOLOCK"
//        case .autoLockUpdated(_):
//            return "AUTOLOCK_UPDATED"
//        case .mechSettingUpdated(_):
//            return "MECH_SETTING_UPDATED"
//        case .timeChanged(_):
//            return "TIME_CHANGED"
//        case .bleLock(_):
//            return "BLE_LOCK"
//        case .manualElse(_):
//            return "MANUAL_ELSE"
//        case .manualLocked(_):
//            return "MANUAL_LOCKED"
//        case .manualUnlocked(_):
//            return "MANUAL_UNLOCKED"
//        case .bleUnLock(_):
//            return "BLE_UNLOCK"
//        case .bleAdvParameterUpdated(_):
//            return "BLE_ADV_PARAM_UPDATED"
//        case .driveFailed(_):
//            return "DRIVE_FAILED"
//        case .driveLocked(_):
//            return "DRIVE_LOCKED"
//        case .driveUnlocked(_):
//            return "DRIVE_UNLOCKED"
//        case .none(_):
//            return "NONE"
//        case .blePositioning(_):
//            return "BLE_POSITIONING"
//        case .drivePosition(_):
//            return "DRIVE_POSITIONING"
//        @unknown default:
//            return ""
//        }
//    }
//    
//    // MARK: - historyTagText
//    var historyTagText: String {
//        let displayText = ""
//        switch self {
//        case .autoLock(_):
//            return displayText + "co.candyhouse.sesame2.AutoLock".localized
//        case .autoLockUpdated(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .mechSettingUpdated(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .timeChanged(_):
//            return displayText + self.event
//        case .bleLock(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .manualElse(_):
//            return displayText + "co.candyhouse.sesame2.manualOperated".localized
//        case .manualLocked(_):
//            return displayText + "co.candyhouse.sesame2.manualLock".localized
//        case .manualUnlocked(_):
//            return displayText + "co.candyhouse.sesame2.manualUnlock".localized
//        case .bleUnLock(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .bleAdvParameterUpdated(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .driveFailed(_):
//            return displayText + self.event
//        case .driveLocked(_):
//            return displayText + self.event
//        case .driveUnlocked(_):
//            return displayText + self.event
//        case .none(_):
//            return displayText + self.event
//        case .blePositioning(_):
//            if let historyTag = self.historyData.historyTag {
//                return displayText + String(decoding: historyTag, as: UTF8.self)
//            } else {
//                return displayText + self.event
//            }
//        case .drivePosition(_):
//            return displayText + self.event
//        @unknown default:
//            return ""
//        }
//    }
//    
//    // MARK: - historyDetail
//    var historyDetail: String {
//        switch self {
//        case .bleLock(_):
//            return ""
//        case .autoLockUpdated(let autoLockUpdated):
//            return "Enabled? \(autoLockUpdated.enabledBefore) -> \(autoLockUpdated.enabledAfter)"
//        case .mechSettingUpdated(let mechSettingUpdated):
//            return """
//            Locked: \(mechSettingUpdated.lockTargetBefore) -> \(mechSettingUpdated.lockTargetAfter), Unlocked: \(mechSettingUpdated.unlockTargetBefore) -> \(mechSettingUpdated.unlockTargetAfter)
//            """
//        case .timeChanged(let historyTimeChanged):
//            return "Time: \(historyTimeChanged.timeBefore) -> \(historyTimeChanged.timeAfter)"
//        case .bleAdvParameterUpdated(let bleAdvParameterChanged):
//            return "Interval: \(bleAdvParameterChanged.intervalBefore) -> \(bleAdvParameterChanged.intervalAfter), TX Power: \(bleAdvParameterChanged.dbmBefore) -> \(bleAdvParameterChanged.dbmAfter)"
//        case .driveFailed(let driveFailed):
//            return "fsmRetCode: \(driveFailed.fsmRetCode), stoppedPosition: \(driveFailed.stoppedPosition), device status: \(driveFailed.deviceStatus)"
//        default:
//            return ""
//        }
//    }
//}
