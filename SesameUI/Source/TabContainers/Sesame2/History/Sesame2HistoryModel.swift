//
//  Sesame2HistoryModel.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

// MARK: - History Data Model
// MARK: Sesame2History
class Sesame2History: Hashable {
    static func == (lhs: Sesame2History, rhs: Sesame2History) -> Bool {
        lhs.sortKey == rhs.sortKey
    }
    
    static func < (lhs: Sesame2History, rhs: Sesame2History) -> Bool {
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

// MARK: - Sesame2HistoryAutoLock
class Sesame2HistoryAutoLock: Sesame2History {
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

// MARK: - Sesame2HistoryAutoLockUpdated
class Sesame2HistoryAutoLockUpdated: Sesame2History {
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

// MARK: - Sesame2HistoryBleAdvParameterUpdated
class Sesame2HistoryBleAdvParameterUpdated: Sesame2History {
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

// MARK: - Sesame2HistoryDriveFailed
class Sesame2HistoryDriveFailed: Sesame2History {
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

// MARK: - Sesame2HistoryDriveLocked
class Sesame2HistoryDriveLocked: Sesame2History {
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

// MARK: - Sesame2HistoryDriveUnlocked
class Sesame2HistoryDriveUnlocked: Sesame2History {
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

// MARK: - Sesame2HistoryLock
class Sesame2HistoryLock: Sesame2History {
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

// MARK: - Sesame2HistoryManualElse
class Sesame2HistoryManualElse: Sesame2History {
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

// MARK: - Sesame2HistoryManualLocked
class Sesame2HistoryManualLocked: Sesame2History {
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

// MARK: - Sesame2HistoryManualUnlocked
class Sesame2HistoryManualUnlocked: Sesame2History {
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

// MARK: - Sesame2HistoryMechSettingUpdated
class Sesame2HistoryMechSettingUpdated: Sesame2History {
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

// MARK: - Sesame2HistoryNone
class Sesame2HistoryNone: Sesame2History {
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

// MARK: - Sesame2HistoryTimeChanged
class Sesame2HistoryTimeChanged: Sesame2History {
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

// MARK: - Sesame2HistoryUnlock
class Sesame2HistoryUnlock: Sesame2History {
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

// MARK: - Sesame2HistoryModel
class Sesame2HistoryModel {
    
    // MARK: Private properties
    private var _histories = Set([Sesame2History]())
    private var histories: Set<Sesame2History> {
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
    
    private var templateTableViewData = [String: [Sesame2History]]()
    
    private var _tableViewData = [String: [Sesame2History]]()
    // MARK: Internal properties
    var tableViewData: [String: [Sesame2History]] {
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
    
    func addOldHistories(_ histories: [Sesame2History]) {
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
            if history is Sesame2HistoryDriveUnlocked, previous is Sesame2HistoryUnlock {
                (previous as! Sesame2HistoryUnlock).isUnlocked = true
                self.histories.remove(history)
            } else if history is Sesame2HistoryDriveLocked, previous is Sesame2HistoryLock {
                (previous as! Sesame2HistoryLock).isLocked = true
                self.histories.remove(history)
            } else if history is Sesame2HistoryDriveLocked, previous is Sesame2HistoryAutoLock {
                (previous as! Sesame2HistoryAutoLock).isLocked = true
                self.histories.remove(history)
            }
        }
    }
    
    func addNewHistories(_ histories: [Sesame2History]) {

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
                    if history is Sesame2HistoryDriveUnlocked, previous is Sesame2HistoryUnlock {
                        (previous as! Sesame2HistoryUnlock).isUnlocked = true
                    } else if history is Sesame2HistoryDriveLocked, previous is Sesame2HistoryLock {
                        (previous as! Sesame2HistoryLock).isLocked = true
                    } else if history is Sesame2HistoryDriveLocked, previous is Sesame2HistoryAutoLock {
                        (previous as! Sesame2HistoryAutoLock).isLocked = true
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
    static func historyModelsFromCHHistories(_ histories: [CHSesame2History], forDevice device: CHSesame2) -> [Sesame2History] {
        var historyModels = [Sesame2History]()
        for history in histories {
            switch history {
            case .autoLock(let autoLockHistory):

                let newHistory = Sesame2HistoryAutoLock(date: autoLockHistory.date,
                                                        deviceID: device.deviceId,
                                                        historyTag: autoLockHistory.historyTag,
                                                        recordID: UInt(Int(autoLockHistory.recordID)),
                                                        sectionIdentifier: autoLockHistory.date.toYMD(),
                                                        isLocked: nil)
                historyModels.append(newHistory)
            case .autoLockUpdated(let autoLockUpdatedHistory):
                let newHistory = Sesame2HistoryAutoLockUpdated(date: autoLockUpdatedHistory.date,
                                              deviceID: device.deviceId,
                                              historyTag: autoLockUpdatedHistory.historyTag,
                                              recordID: UInt(autoLockUpdatedHistory.recordID),
                                              sectionIdentifier: autoLockUpdatedHistory.date.toYMD(),
                                              enabledAfter: Int(autoLockUpdatedHistory.enabledAfter),
                                              enabledBefore: Int(autoLockUpdatedHistory.enabledBefore))
                historyModels.append(newHistory)
            case .mechSettingUpdated(let mechSettingUpdatedHistory):
                let newHistory = Sesame2HistoryMechSettingUpdated(date: mechSettingUpdatedHistory.date,
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
                let newHistory = Sesame2HistoryTimeChanged(date: timeChaedHistoryHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: timeChaedHistoryHistory.historyTag,
                                                           recordID: UInt(timeChaedHistoryHistory.recordID),
                                                           sectionIdentifier: timeChaedHistoryHistory.date.toYMD(),
                                                           newTime: timeChaedHistoryHistory.timeAfter,
                                                           timeBefore: timeChaedHistoryHistory.timeBefore)
                historyModels.append(newHistory)
            case .bleLock(let lockHistory):
                let newHistory = Sesame2HistoryLock(date: lockHistory.date,
                                                    deviceID: device.deviceId,
                                                    historyTag: lockHistory.historyTag,
                                                    recordID: UInt(lockHistory.recordID),
                                                    sectionIdentifier: lockHistory.date.toYMD(),
                                                    isLocked: nil)
                historyModels.append(newHistory)
            case .manualElse(let manualElseHisotry):
                let newHistory = Sesame2HistoryManualElse(date: manualElseHisotry.date,
                                                          deviceID: device.deviceId,
                                                          historyTag: manualElseHisotry.historyTag,
                                                          recordID: UInt(manualElseHisotry.recordID),
                                                          sectionIdentifier: manualElseHisotry.date.toYMD())
                historyModels.append(newHistory)
            case .manualLocked(let manualLockedHistory):
                let newHistory = Sesame2HistoryManualLocked(date: manualLockedHistory.date,
                                                            deviceID: device.deviceId,
                                                            historyTag: manualLockedHistory.historyTag,
                                                            recordID: UInt(manualLockedHistory.recordID),
                                                            sectionIdentifier: manualLockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .manualUnlocked(let manualUnlockedHistory):
                let newHistory = Sesame2HistoryManualUnlocked(date: manualUnlockedHistory.date,
                                                              deviceID: device.deviceId,
                                                              historyTag: manualUnlockedHistory.historyTag,
                                                              recordID: UInt(manualUnlockedHistory.recordID),
                                                              sectionIdentifier: manualUnlockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .bleUnLock(let bleUnLockHistory):
                let newHistory = Sesame2HistoryUnlock(date: bleUnLockHistory.date,
                                                      deviceID: device.deviceId,
                                                      historyTag: bleUnLockHistory.historyTag,
                                                      recordID: UInt(bleUnLockHistory.recordID),
                                                      sectionIdentifier: bleUnLockHistory.date.toYMD(),
                                                      isUnlocked: nil)
                historyModels.append(newHistory)
            case .bleAdvParameterUpdated(let bleAdvUpdatedHistory):
                let newHistory = Sesame2HistoryBleAdvParameterUpdated(date: bleAdvUpdatedHistory.date,
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
                let newHistory = Sesame2HistoryDriveLocked(date: driveLockHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: driveLockHistory.historyTag,
                                                           recordID: UInt(driveLockHistory.recordID),
                                                           sectionIdentifier: driveLockHistory.date.toYMD())
                historyModels.append(newHistory)
            case .driveUnlocked(let driveUnlockedHistory):
                let newHistory = Sesame2HistoryDriveUnlocked(date: driveUnlockedHistory.date,
                                                             deviceID: device.deviceId,
                                                             historyTag: driveUnlockedHistory.historyTag,
                                                             recordID: UInt(driveUnlockedHistory.recordID),
                                                             sectionIdentifier: driveUnlockedHistory.date.toYMD())
                historyModels.append(newHistory)
            case .driveFailed(let driveFailedHistory):
                let newHistory = Sesame2HistoryDriveFailed(date: driveFailedHistory.date,
                                                           deviceID: device.deviceId,
                                                           historyTag: driveFailedHistory.historyTag,
                                                           recordID: UInt(driveFailedHistory.recordID),
                                                           sectionIdentifier: driveFailedHistory.date.toYMD(),
                                                           deviceStatus: driveFailedHistory.deviceStatus.description(),
                                                           fsmRetCode: Int(driveFailedHistory.fsmRetCode), stoppedPosition:
                                                            Int(driveFailedHistory.stoppedPosition))
                historyModels.append(newHistory)
            case .none(let noneHistory):
                let newHistory = Sesame2HistoryDriveLocked(date: noneHistory.date,
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
