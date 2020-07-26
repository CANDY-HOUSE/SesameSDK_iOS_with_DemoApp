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
        guard let date = history.date else {
            return ""
        }
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
        switch history {
        case _ as Sesame2HistoryAutoLockMO:
            return "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
        case _ as Sesame2HistoryAutoLockUpdatedMO:
            return "AUTOLOCK_UPDATED"
        case _ as Sesame2HistoryMechSettingUpdatedMO:
            return "MECH_SETTING_UPDATED"
        case _ as Sesame2HistoryTimeChangedMO:
            return "TIME_CHANGED"
        case _ as Sesame2HistoryLockMO:
            return "BLE_LOCK"
        case _ as Sesame2HistoryManualElseMO:
            return "co.candyhouse.sesame-sdk-test-app.manualOperated".localized
        case _ as Sesame2HistoryManualLockedMO:
            return "co.candyhouse.sesame-sdk-test-app.manualLock".localized
        case _ as Sesame2HistoryManualUnlockedMO:
            return "co.candyhouse.sesame-sdk-test-app.manualUnlock".localized
        case _ as Sesame2HistoryUnlockMO:
            return "BLE_UNLOCK"
        default:
            return ""
        }
    }
    
    public var userLabelText: String {
        switch history {
        case _ as Sesame2HistoryAutoLockMO:
            return "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
        case _ as Sesame2HistoryAutoLockUpdatedMO:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case _ as Sesame2HistoryMechSettingUpdatedMO:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case _ as Sesame2HistoryTimeChangedMO:
            return "TIME_CHANGED"
        case _ as Sesame2HistoryLockMO:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case _ as Sesame2HistoryManualElseMO:
            return "co.candyhouse.sesame-sdk-test-app.manualOperated".localized
        case _ as Sesame2HistoryManualLockedMO:
            return "co.candyhouse.sesame-sdk-test-app.manualLock".localized
        case _ as Sesame2HistoryManualUnlockedMO:
            return "co.candyhouse.sesame-sdk-test-app.manualUnlock".localized
        case _ as Sesame2HistoryUnlockMO:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        default:
            return ""
        }
    }

    public var avatarImage: String {
        switch history {
        case _ as Sesame2HistoryAutoLockMO:
            return "autolock"
        case _ as Sesame2HistoryAutoLockUpdatedMO:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryMechSettingUpdatedMO:
            return "icons_outlined_setting"
        case _ as Sesame2HistoryTimeChangedMO:
            return "iconfinder_9_3898370"
        case _ as Sesame2HistoryLockMO:
            return "icon_lock"
        case _ as Sesame2HistoryManualElseMO:
            return "handmove"
        case _ as Sesame2HistoryManualLockedMO:
            return "icon_lock"
        case _ as Sesame2HistoryManualUnlockedMO:
            return "icon_unlock"
        case _ as Sesame2HistoryUnlockMO:
            return "icon_unlock"
        case _ as Sesame2HistoryBleAdvParameterUpdatedMO:
            return "icons_outlined_setting"
        default:
            return ""
        }
    }
    
    func information() -> String {
        switch history {
        case _ as Sesame2HistoryLockMO:
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
        case let bleAdvParameterChanged as Sesame2HistoryBleAdvParameterUpdatedMO:
            return "Interval: \(bleAdvParameterChanged.intervalBefore) -> \(bleAdvParameterChanged.intervalAfter), TX Power: \(bleAdvParameterChanged.dbmBefore) -> \(bleAdvParameterChanged.dbmAfter)"
        default:
            return ""
        }
    }
}
