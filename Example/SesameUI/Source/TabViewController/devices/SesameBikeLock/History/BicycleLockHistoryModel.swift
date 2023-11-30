//
//  BicycleLockHistoryModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

// MARK: - History Data Model



// MARK: BicycleLockHistory
class BikeLockHistory: Hashable {
    static func == (lhs: BikeLockHistory, rhs: BikeLockHistory) -> Bool {
        lhs.sortKey == rhs.sortKey
    }
    
    static func < (lhs: BikeLockHistory, rhs: BikeLockHistory) -> Bool {
        lhs.sortKey < rhs.sortKey
    }
    
    var sortKey: UInt {
        UInt(date.timeIntervalSince1970) * UInt(pow(10.0, 10.0)) + UInt(recordID)
    }
    
    var date: Date
    var deviceID: UUID
    var historyTag: Data?
    var recordID: UInt
    var sectionIdentifier: String
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        self.date = date
        self.deviceID = deviceID
        self.historyTag = historyTag
        self.recordID = recordID
        self.sectionIdentifier = sectionIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(recordID)
    }
}

extension BikeLockHistory {
    
    var avatarImage: String {
        switch self {
        case _ as BicycleLockHistoryAutoLock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "autolock"
            } else {
                return (self as! BicycleLockHistoryAutoLock).isLocked == true ? "icon_locked" : "autolock"
            }
        case _ as BicycleLockHistoryAutoLockUpdated:
            return "icons_outlined_setting"
        case _ as BicycleLockHistoryMechSettingUpdated:
            return "icons_outlined_setting"
        case _ as BicycleLockHistoryTimeChanged:
            return "iconfinder_9_3898370"
        case _ as BicycleLockHistoryLock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "icon_lock"
            } else {
                return (self as! BicycleLockHistoryLock).isLocked == true ? "icon_locked" : "icon_lock"
            }
        case _ as BicycleLockHistoryManualElse:
            return "handmove"
        case _ as BicycleLockHistoryManualLocked:
            return "icon_lock"
        case _ as BicycleLockHistoryManualUnlocked:
            return "icon_unlock"
        case _ as BicycleLockHistoryUnlock:
            if CHConfiguration.shared.isDebugModeEnabled() {
                return "icon_unlock"
            } else {
                return (self as! BicycleLockHistoryUnlock).isUnlocked == true ? "icon_unlocked" : "icon_unlock"
            }
        case _ as BicycleLockHistoryBleAdvParameterUpdated:
            return "icons_outlined_setting"
        case _ as BicycleLockHistoryDriveFailed:
            return "icons_outlined_setting"
        case _ as BicycleLockHistoryDriveLocked:
            return "icon_locked"
        case _ as BicycleLockHistoryDriveUnlocked:
            return "icon_unlocked"
        case _ as BicycleLockHistoryNone:
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
        case _ as BicycleLockHistoryAutoLock:
            return "AUTOLOCK"
        case _ as BicycleLockHistoryAutoLockUpdated:
            return "AUTOLOCK_UPDATED"
        case _ as BicycleLockHistoryMechSettingUpdated:
            return "MECH_SETTING_UPDATED"
        case _ as BicycleLockHistoryTimeChanged:
            return "TIME_CHANGED"
        case _ as BicycleLockHistoryLock:
            return "BLE_LOCK"
        case _ as BicycleLockHistoryManualElse:
            return "MANUAL_ELSE"
        case _ as BicycleLockHistoryManualLocked:
            return "MANUAL_LOCKED"
        case _ as BicycleLockHistoryManualUnlocked:
            return "MANUAL_UNLOCKED"
        case _ as BicycleLockHistoryUnlock:
            return "BLE_UNLOCK"
        case _ as BicycleLockHistoryBleAdvParameterUpdated:
            return "BLE_ADV_PARAM_UPDATED"
        case _ as BicycleLockHistoryDriveFailed:
            return "DRIVE_FAILED"
        case _ as BicycleLockHistoryDriveLocked:
            return "DRIVE_LOCKED"
        case _ as BicycleLockHistoryDriveUnlocked:
            return "DRIVE_UNLOCKED"
        case _ as BicycleLockHistoryNone:
            return "NONE"
        default:
            return ""
        }
    }
    
    var historyTagText: String {
        let displayText = CHConfiguration.shared.isDebugModeEnabled() ? "\(self.recordID): " : ""
        switch self {
        case _ as BicycleLockHistoryAutoLock:
            return displayText + "co.candyhouse.sesame-sdk-test-app.AutoLock".localized
        case _ as BicycleLockHistoryAutoLockUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as BicycleLockHistoryMechSettingUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as BicycleLockHistoryTimeChanged:
            return displayText + self.event
        case _ as BicycleLockHistoryLock:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as BicycleLockHistoryManualElse:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualOperated".localized
        case _ as BicycleLockHistoryManualLocked:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualLock".localized
        case _ as BicycleLockHistoryManualUnlocked:
            return displayText + "co.candyhouse.sesame-sdk-test-app.manualUnlock".localized
        case _ as BicycleLockHistoryUnlock:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as BicycleLockHistoryBleAdvParameterUpdated:
            if let historyTag = self.historyTag {
                return displayText + String(decoding: historyTag, as: UTF8.self)
            } else {
                return displayText + self.event
            }
        case _ as BicycleLockHistoryDriveFailed:
            return displayText + self.event
        case _ as BicycleLockHistoryDriveLocked:
            return displayText + self.event
        case _ as BicycleLockHistoryDriveUnlocked:
            return displayText + self.event
        case _ as BicycleLockHistoryNone:
            return displayText + self.event
        default:
            return ""
        }
    }
    
    var historyDetail: String {
        switch self {
        case _ as BicycleLockHistoryLock:
            return ""
        case let autoLockUpdated as BicycleLockHistoryAutoLockUpdated:
            return "Enabled? \(autoLockUpdated.enabledBefore) -> \(autoLockUpdated.enabledAfter)"
        case let mechSettingUpdated as BicycleLockHistoryMechSettingUpdated:
            return """
            Locked: \(mechSettingUpdated.lockTargetBefore) -> \(mechSettingUpdated.lockTargetAfter), Unlocked: \(mechSettingUpdated.unlockTargetBefore) -> \(mechSettingUpdated.unlockTargetAfter)
            """
        case let historyTimeChanged as BicycleLockHistoryTimeChanged:
            return "Time: \(historyTimeChanged.timeBefore) -> \(historyTimeChanged.newTime)"
        case let bleAdvParameterChanged as BicycleLockHistoryBleAdvParameterUpdated:
            return "Interval: \(bleAdvParameterChanged.intervalBefore) -> \(bleAdvParameterChanged.intervalAfter), TX Power: \(bleAdvParameterChanged.dbmBefore) -> \(bleAdvParameterChanged.dbmAfter)"
        case let driveFailed as BicycleLockHistoryDriveFailed:
            return "fsmRetCode: \(driveFailed.fsmRetCode), stoppedPosition: \(driveFailed.stoppedPosition), device status: \(driveFailed.deviceStatus)"
        default:
            return ""
        }
    }
}

// MARK: - BicycleLockHistoryAutoLock
class BicycleLockHistoryAutoLock: BikeLockHistory {
    var isLocked: Bool?
    
    init(date: Date, deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         isLocked: Bool?) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
        self.isLocked = isLocked
    }
}

// MARK: - BicycleLockHistoryAutoLockUpdated
class BicycleLockHistoryAutoLockUpdated: BikeLockHistory {
    let enabledAfter: Int
    let enabledBefore: Int
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         enabledAfter: Int,
         enabledBefore: Int) {
        self.enabledAfter = enabledAfter
        self.enabledBefore = enabledBefore
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryBleAdvParameterUpdated
class BicycleLockHistoryBleAdvParameterUpdated: BikeLockHistory {
    let dbmAfter: Int
    let dbmBefore: Int
    let intervalAfter: Int
    let intervalBefore: Int
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         dbmAfter: Int,
         dbmBefore: Int,
         intervalAfter: Int,
         intervalBefore: Int) {
        self.dbmAfter = dbmAfter
        self.dbmBefore = dbmBefore
        self.intervalAfter = intervalAfter
        self.intervalBefore = intervalBefore
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryDriveFailed
class BicycleLockHistoryDriveFailed: BikeLockHistory {
    let deviceStatus: String
    let fsmRetCode: Int
    let stoppedPosition: Int
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         deviceStatus: String,
         fsmRetCode: Int,
         stoppedPosition: Int) {
        self.deviceStatus = deviceStatus
        self.fsmRetCode = fsmRetCode
        self.stoppedPosition = stoppedPosition
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryDriveLocked
class BicycleLockHistoryDriveLocked: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryDriveUnlocked
class BicycleLockHistoryDriveUnlocked: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryLock
class BicycleLockHistoryLock: BikeLockHistory {
    var isLocked: Bool?
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         isLocked: Bool?) {
        self.isLocked = isLocked
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryManualElse
class BicycleLockHistoryManualElse: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryManualLocked
class BicycleLockHistoryManualLocked: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryManualUnlocked
class BicycleLockHistoryManualUnlocked: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryMechSettingUpdated
class BicycleLockHistoryMechSettingUpdated: BikeLockHistory {
    let lockTargetAfter: Int
    let lockTargetBefore: Int
    let unlockTargetAfter: Int
    let unlockTargetBefore: Int
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         lockTargetAfter: Int,
         lockTargetBefore: Int,
         unlockTargetAfter: Int,
         unlockTargetBefore: Int) {
        self.lockTargetAfter = lockTargetAfter
        self.lockTargetBefore = lockTargetBefore
        self.unlockTargetAfter = unlockTargetAfter
        self.unlockTargetBefore = unlockTargetBefore
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryNone
class BicycleLockHistoryNone: BikeLockHistory {
    override init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryTimeChanged
class BicycleLockHistoryTimeChanged: BikeLockHistory {
    let newTime: Date
    let timeBefore: Date
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         newTime: Date,
         timeBefore: Date) {
        self.newTime = newTime
        self.timeBefore = timeBefore
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
    }
}

// MARK: - BicycleLockHistoryUnlock
class BicycleLockHistoryUnlock: BikeLockHistory {
    var isUnlocked: Bool?
    
    init(date: Date,
         deviceID: UUID,
         historyTag: Data?,
         recordID: UInt,
         sectionIdentifier: String,
         isUnlocked: Bool?) {
        super.init(date: date,
                   deviceID: deviceID,
                   historyTag: historyTag,
                   recordID: recordID,
                   sectionIdentifier: sectionIdentifier)
        self.isUnlocked = isUnlocked
    }
}

private let lockQueue = DispatchQueue(label: "co.sesameUI.history.queue")

// MARK: - BicycleLockHistoryModel
class BikeLockHistoryModel {
    
    // MARK: Private properties
    private var _histories = Set([BikeLockHistory]())
    private var histories: Set<BikeLockHistory> {
        set {
            lockQueue.sync {
                _histories = newValue
            }
        }
        
        get {
            lockQueue.sync {
                return _histories
            }
        }
        
    }
    
    private var _sections = Set([String]())
    private var sections: Set<String> {
        set {
            lockQueue.sync {
                _sections = newValue
            }
        }
        
        get {
            lockQueue.sync {
                _sections
            }
        }
    }
    
    private var templateTableViewData = [String: [BikeLockHistory]]()
    
    private var _tableViewData = [String: [BikeLockHistory]]()
    // MARK: Internal properties
    var tableViewData: [String: [BikeLockHistory]] {
        set {
            lockQueue.sync {
                _tableViewData = newValue
            }
        }
        
        get {
            lockQueue.sync {
                return _tableViewData
            }
        }
    }

    // MARK: Methods
    func reloadData() {
        tableViewData = templateTableViewData
        
        // History Debug Log
//        let key = self.tableViewData.keys.first
//        var index = 0
//        for history in self.tableViewData[key!]! {
//            L.d("history: ", index, history.recordID, history.historyTagText)
//            index += 1
//        }
    }
    
    func addOldHistories(_ histories: [BikeLockHistory]) {
        let uniqueHistories = histories.filter { history -> Bool in
            !self.histories.contains(history)
        }
        
        if uniqueHistories.count == 0 {
            return
        }

        let sortedHistories = uniqueHistories.sorted(by: <)
        
        for history in sortedHistories {
            self.histories.insert(history)
            sections.insert(history.sectionIdentifier)
        }
        
        if !CHConfiguration.shared.isDebugModeEnabled() {
            filterDrivedHistory()
        }
        
        for section in sections {
            templateTableViewData[section] = self.histories.filter({ $0.sectionIdentifier == section }).sorted(by: <)
        }
    }
    
    private func filterDrivedHistory() {
        let currentHistories = Array(self.histories).sorted(by: <)
        for (index, history) in currentHistories.enumerated() {
            guard index > 0 else {
                continue
            }
            let previous = currentHistories[index - 1]
            if history is BicycleLockHistoryDriveUnlocked, previous is BicycleLockHistoryUnlock {
                (previous as! BicycleLockHistoryUnlock).isUnlocked = true
                self.histories.remove(history)
            } else if history is BicycleLockHistoryDriveLocked, previous is BicycleLockHistoryLock {
                (previous as! BicycleLockHistoryLock).isLocked = true
                self.histories.remove(history)
            } else if history is BicycleLockHistoryDriveLocked, previous is BicycleLockHistoryAutoLock {
                (previous as! BicycleLockHistoryAutoLock).isLocked = true
                self.histories.remove(history)
            }
        }
    }
    
    func addNewHistories(_ histories: [BikeLockHistory]) {

        let uniqueHistories = histories.filter { history -> Bool in
            !self.histories.contains(history)
        }
        
        guard uniqueHistories.count > 0 else {
            return
        }

        let sortedHistories = uniqueHistories.sorted(by: <)
        
        for history in sortedHistories {
            
            if CHConfiguration.shared.isDebugModeEnabled() {
                self.histories.insert(history)
                self.sections.insert(history.sectionIdentifier)
            } else {
                
                if let previous = Array(self.histories).sorted(by: <).last {
                    if history is BicycleLockHistoryDriveUnlocked, previous is BicycleLockHistoryUnlock {
                        (previous as! BicycleLockHistoryUnlock).isUnlocked = true
                    } else if history is BicycleLockHistoryDriveLocked, previous is BicycleLockHistoryLock {
                        (previous as! BicycleLockHistoryLock).isLocked = true
                    } else if history is BicycleLockHistoryDriveLocked, previous is BicycleLockHistoryAutoLock {
                        (previous as! BicycleLockHistoryAutoLock).isLocked = true
                    } else {
                        self.histories.insert(history)
                        self.sections.insert(history.sectionIdentifier)
                    }
                } else {
                    self.histories.insert(history)
                    self.sections.insert(history.sectionIdentifier)
                }
            }
        }
        
        for section in sections {
            templateTableViewData[section] = self.histories.filter({ $0.sectionIdentifier == section }).sorted(by: <)
        }
    }

    // MARK: HistoryModel factory method
    static func historyModelsFromCHHistories(_ histories: [CHBikeLockHistory], forDevice device: CHBikeLock) -> [BikeLockHistory] {
        var historyModels = [BikeLockHistory]()
        for history in histories {
            switch history {
            case .autoLock(let autoLockHistory):

                let newHistory = BicycleLockHistoryAutoLock(date: autoLockHistory.date,
                                                        deviceID: device.deviceId,
                                                        historyTag: autoLockHistory.historyTag,
                                                        recordID: UInt(Int(autoLockHistory.recordID)),
                                                        sectionIdentifier: autoLockHistory.date.toYMD(),
                                                        isLocked: nil)
                historyModels.append(newHistory)
            case .autoLockUpdated(let autoLockUpdatedHistory):
                let newHistory = BicycleLockHistoryAutoLockUpdated(date: autoLockUpdatedHistory.date,
                                              deviceID: device.deviceId,
                                              historyTag: autoLockUpdatedHistory.historyTag,
                                              recordID: UInt(autoLockUpdatedHistory.recordID),
                                              sectionIdentifier: autoLockUpdatedHistory.date.toYMD(),
                                              enabledAfter: Int(autoLockUpdatedHistory.enabledAfter),
                                              enabledBefore: Int(autoLockUpdatedHistory.enabledBefore))
                historyModels.append(newHistory)
            case .mechSettingUpdated(let mechSettingUpdatedHistory):
                let newHistory = BicycleLockHistoryMechSettingUpdated(date: mechSettingUpdatedHistory.date,
                                                                  deviceID: device.deviceId,
                                                                  historyTag: mechSettingUpdatedHistory.historyTag,
                                                                  recordID: UInt(mechSettingUpdatedHistory.recordID),
                                                                  sectionIdentifier: mechSettingUpdatedHistory.date.toYMD(),
                                                                  lockTargetAfter: Int(mechSettingUpdatedHistory.lockTargetAfter),
                                                                  lockTargetBefore: Int(mechSettingUpdatedHistory.lockTargetBefore),
                                                                  unlockTargetAfter: Int(mechSettingUpdatedHistory.unlockTargetAfter),
                                                                  unlockTargetBefore: Int(mechSettingUpdatedHistory.unlockTargetBefore))
                historyModels.append(newHistory)
            case .timeChanged(let timeChaedHistoryHistory):
                let newHistory = BicycleLockHistoryTimeChanged(date: timeChaedHistoryHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: timeChaedHistoryHistory.historyTag,
                                                           recordID: UInt(timeChaedHistoryHistory.recordID),
                                                           sectionIdentifier: timeChaedHistoryHistory.date.toYMD(),
                                                           newTime: timeChaedHistoryHistory.timeAfter,
                                                           timeBefore: timeChaedHistoryHistory.timeBefore)
                historyModels.append(newHistory)
            case .bleLock(let lockHistory):
                let newHistory = BicycleLockHistoryLock(date: lockHistory.date,
                                                    deviceID: device.deviceId,
                                                    historyTag: lockHistory.historyTag,
                                                    recordID: UInt(lockHistory.recordID),
                                                    sectionIdentifier: lockHistory.date.toYMD(),
                                                    isLocked: nil)
                historyModels.append(newHistory)
            case .manualElse(let manualElseHisotry):
                let newHistory = BicycleLockHistoryManualElse(date: manualElseHisotry.date,
                                                          deviceID: device.deviceId,
                                                          historyTag: manualElseHisotry.historyTag,
                                                          recordID: UInt(manualElseHisotry.recordID),
                                                          sectionIdentifier: manualElseHisotry.date.toYMD())
                historyModels.append(newHistory)
            case .manualLocked(let manualLockedHistory):
                let newHistory = BicycleLockHistoryManualLocked(date: manualLockedHistory.date,
                                                            deviceID: device.deviceId,
                                                            historyTag: manualLockedHistory.historyTag,
                                                            recordID: UInt(manualLockedHistory.recordID),
                                                            sectionIdentifier: manualLockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .manualUnlocked(let manualUnlockedHistory):
                let newHistory = BicycleLockHistoryManualUnlocked(date: manualUnlockedHistory.date,
                                                              deviceID: device.deviceId,
                                                              historyTag: manualUnlockedHistory.historyTag,
                                                              recordID: UInt(manualUnlockedHistory.recordID),
                                                              sectionIdentifier: manualUnlockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .bleUnLock(let bleUnLockHistory):
                let newHistory = BicycleLockHistoryUnlock(date: bleUnLockHistory.date,
                                                      deviceID: device.deviceId,
                                                      historyTag: bleUnLockHistory.historyTag,
                                                      recordID: UInt(bleUnLockHistory.recordID),
                                                      sectionIdentifier: bleUnLockHistory.date.toYMD(),
                                                      isUnlocked: nil)
                historyModels.append(newHistory)
            case .bleAdvParameterUpdated(let bleAdvUpdatedHistory):
                let newHistory = BicycleLockHistoryBleAdvParameterUpdated(date: bleAdvUpdatedHistory.date,
                                                                      deviceID: device.deviceId,
                                                                      historyTag:
                                                                        bleAdvUpdatedHistory.historyTag,
                                                                      recordID: UInt(bleAdvUpdatedHistory.recordID),
                                                                      sectionIdentifier: bleAdvUpdatedHistory.date.toYMD(),
                                                                      dbmAfter: Int(bleAdvUpdatedHistory.dbmAfter),
                                                                      dbmBefore: Int(bleAdvUpdatedHistory.dbmBefore),
                                                                      intervalAfter: Int(bleAdvUpdatedHistory.intervalAfter),
                                                                      intervalBefore: Int(bleAdvUpdatedHistory.intervalBefore))
                historyModels.append(newHistory)
            case .driveLocked(let driveLockHistory):
                let newHistory = BicycleLockHistoryDriveLocked(date: driveLockHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: driveLockHistory.historyTag,
                                                           recordID: UInt(driveLockHistory.recordID),
                                                           sectionIdentifier: driveLockHistory.date.toYMD())
                historyModels.append(newHistory)
            case .driveUnlocked(let driveUnlockedHistory):
                let newHistory = BicycleLockHistoryDriveUnlocked(date: driveUnlockedHistory.date,
                                                             deviceID: device.deviceId,
                                                             historyTag: driveUnlockedHistory.historyTag,
                                                             recordID: UInt(driveUnlockedHistory.recordID),
                                                             sectionIdentifier: driveUnlockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .driveFailed(let driveFailedHistory):
                let newHistory = BicycleLockHistoryDriveFailed(date: driveFailedHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: driveFailedHistory.historyTag,
                                                           recordID: UInt(driveFailedHistory.recordID),
                                                           sectionIdentifier: driveFailedHistory.date.toYMD(),
                                                           deviceStatus: driveFailedHistory.deviceStatus.description(),
                                                           fsmRetCode: Int(driveFailedHistory.fsmRetCode), stoppedPosition:
                                                            Int(driveFailedHistory.stoppedPosition))
                historyModels.append(newHistory)
            case .none(let noneHistory):
                let newHistory = BicycleLockHistoryDriveLocked(date: noneHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: noneHistory.historyTag,
                                                           recordID: UInt(noneHistory.recordID),
                                                           sectionIdentifier: noneHistory.date.toYMD())
                historyModels.append(newHistory)
            @unknown default:
                break
            }
        }
        return historyModels
    }
}
