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

public final class SSM2HistoryCellViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    
    let history: SSMHistoryMO
    
    init(history: SSMHistoryMO) {
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
        switch SSM2HistoryType(rawValue: UInt8(history.historyType))! {
        case SSM2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case SSM2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case SSM2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case SSM2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case SSM2HistoryType.BLE_LOCK:
            return "BLE_LOCK"
        case SSM2HistoryType.BLE_UNLOCK:
            return "BLE_UNLOCK"
        case SSM2HistoryType.TIME_CHANGED:
            return "TIME_CHANGED"
        case SSM2HistoryType.AUTOLOCK_UPDATED:
            return "AUTOLOCK_UPDATED"
        case SSM2HistoryType.MECH_SETTING_UPDATED:
            return "MECH_SETTING_UPDATED"
        case SSM2HistoryType.NONE:
            return "NONE"
        }
    }
    
    public var userLabelText: String {
        switch SSM2HistoryType(rawValue: UInt8(history.historyType))! {
        case SSM2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case SSM2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case SSM2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case SSM2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case SSM2HistoryType.BLE_LOCK:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case SSM2HistoryType.BLE_UNLOCK:
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
        switch SSM2HistoryType(rawValue: UInt8(history.historyType))! {
        case SSM2HistoryType.BLE_LOCK,
             SSM2HistoryType.MANUAL_LOCKED:
            return "icon_lock"
        case SSM2HistoryType.BLE_UNLOCK,
             SSM2HistoryType.MANUAL_UNLOCKED:
            return "icon_unlock"
        case SSM2HistoryType.MANUAL_ELSE:
            return "handmove"
        case SSM2HistoryType.AUTOLOCK:
            return "autolock"
        case SSM2HistoryType.MECH_SETTING_UPDATED:
            return "icons_outlined_setting"
        case SSM2HistoryType.TIME_CHANGED:
            return "iconfinder_9_3898370"
        case SSM2HistoryType.AUTOLOCK_UPDATED:
            return "icons_outlined_setting"
        default:
            return ""
        }
    }
}
