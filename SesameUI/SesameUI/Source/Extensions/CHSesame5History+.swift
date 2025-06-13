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

    // MARK: - avatarImage
    var avatarImage: String {
        switch self {
        case .autoLock(_):                                  return "history_lock"
        case .bleLock(_), .wm2Lock(_), .webLock(_):         return "history_lock"
        case .bleUnlock(_), .wm2Unlock(_), .webUnlock(_):   return "history_unlock"
        case .manualLocked(_):                              return "history_lock"
        case .manualUnlocked(_):                            return "history_unlock"
        default:
            return ""
        }
    }

    var historyTypeImage: String {
        switch self {
        case .autoLock(_):                          return "history_auto"
        case .bleLock(_),.bleUnlock(_):             return "bluetooth"
        case .manualLocked(_), .manualUnlocked(_):  return "history_manul"
        case .wm2Lock(_), .wm2Unlock(_):            return "wifi"
        case .webLock(_), .webUnlock(_):            return "pc"
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
        case .manualLocked(_):
            return displayText + "co.candyhouse.sesame2.manualLock".localized
        case .manualUnlocked(_):
            return displayText + "co.candyhouse.sesame2.manualUnlock".localized
        case .wm2Lock(_), .wm2Unlock(_), .bleLock(_), .bleUnlock(_), .webLock(_), .webUnlock(_):
            if let historyTag = self.historyData.historyTag {
                return displayText + parseHistoryTag(historyTag)
            } else {
                return displayText
            }
        @unknown default:
            return ""
        }
    }

    func parseHistoryTag(_ historyTag: Data) -> String {
        return String(decoding: historyTag, as: UTF8.self)
    }
    var dateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss a"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return "\(dateFormatter.string(from: historyData.date))"
    }
}
