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
        return dateFormatter.string(from: date)
    }
    
    public var eventImage: String {
        ""
    }
    
    public var userLabelText: String {
        switch SS2HistoryType(rawValue: UInt8(history.historyType))! {
        case SS2HistoryType.AUTOLOCK:
            return "autolock".localStr
        case SS2HistoryType.MANUAL_LOCKED:
            return "manualLock".localStr
        case SS2HistoryType.MANUAL_UNLOCKED:
            return "manualUnlock".localStr
        case SS2HistoryType.MANUAL_ELSE:
            return "manualOperated".localStr
        case SS2HistoryType.BLE_LOCK:
            if let historyTag = history.historyTag {
                return String(decoding: historyTag, as: UTF8.self)
            } else {
                return ""
            }
        case SS2HistoryType.BLE_UNLOCK:
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
        switch SS2HistoryType(rawValue: UInt8(history.historyType))! {
        case SS2HistoryType.BLE_LOCK,
             SS2HistoryType.MANUAL_LOCKED:
            return "icon_lock"
        case SS2HistoryType.BLE_UNLOCK,
             SS2HistoryType.MANUAL_UNLOCKED:
            return "icon_unlock"
        case SS2HistoryType.MANUAL_ELSE:
            return "handmove"
        case SS2HistoryType.AUTOLOCK:
            return "autolock"
        default:
            return ""
        }
    }
}
