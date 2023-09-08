//
//  Sesame2BleDevice+History.swift
//  Sesame2SDK
//
//  Created by Tse on 2019/10/07.
//  Copyright © 2019 Candyhouse. All rights reserved.
//

extension CHSesame2Device {

    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        if self.checkBle(result) { return}
        guard let fwVersion = fwVersion, fwVersion > 0 else { return}
        URLSession.isInternetReachable { isInternetReachable in
            let deleteHistory = isInternetReachable == true ? "01":"00"
            self.sendCommand(.init(.read, .history, deleteHistory.hexStringtoData())) { (result) in
                
                if result.cmdResultCode == .success {
                    
                    let histitem = result.data.copyData
                    
                    guard let recordId = histitem[safeBound: 0...3]?.copyData,
                          let type = histitem[safeBound: 4...4]?.copyData,
                          let timeData = histitem[safeBound: 5...12]?.copyData else {
    //                    L.d("藍芽", "RESPONSE", "解析失敗1", histitem.toHexString())
                        return
                    }
                    let hisContent = histitem[13...].copyData
                    
                    let record_id_Int32: Int32 = recordId.withUnsafeBytes({ $0.bindMemory(to: Int32.self).first! })
                    let timestampInt64: UInt64 = timeData.withUnsafeBytes({ $0.bindMemory(to: UInt64.self).first! })
                    
                    guard var historyType: Sesame2HistoryTypeEnum = Sesame2HistoryTypeEnum(rawValue: type.bytes[0]) else { return }
                    
                    var historyContent = hisContent
                    
                    if historyType == .BLE_LOCK || historyType == .BLE_UNLOCK {
                        let histag = hisContent[18...]
                        let tagcount_historyTag = histag.copyData
                        let tagcount = UInt8(tagcount_historyTag[0])
                        
                        // Parse lock types
                        let originalTagCount = tagcount % Sesame2HistoryLockOpType.BASE.rawValue
                        let historyOpType = Sesame2HistoryLockOpType(rawValue: tagcount / Sesame2HistoryLockOpType.BASE.rawValue)
                        if historyType == .BLE_LOCK, historyOpType == .WM2 {
                            historyType = Sesame2HistoryTypeEnum.WM2_LOCK
                        } else if historyType == .BLE_LOCK, historyOpType == .WEB {
                            historyType = Sesame2HistoryTypeEnum.WEB_LOCK
                        } else if historyType == .BLE_UNLOCK, historyOpType == .WM2 {
                            historyType = Sesame2HistoryTypeEnum.WM2_UNLOCK
                        } else if historyType == .BLE_UNLOCK, historyOpType == .WEB {
                            historyType = Sesame2HistoryTypeEnum.WEB_UNLOCK
                        }
                        
                        if historyOpType == .WEB || historyOpType == .WM2 {
                            if let type = Sesame2HistoryTypeEnum(rawValue: tagcount / 30) {
                                historyType = type
                            } else {
                                historyType = .NONE
                            }
                        }
                        
                        historyContent = hisContent[...17].copyData + originalTagCount.data + hisContent[19...].copyData
                    }
                    
                    let chHistoryEvent = CHSesame2HistoryEvent(type: historyType,
                                                               time: timestampInt64,
                                                               recordID: record_id_Int32,
                                                               content: historyContent)
                    if let sesame2History = self.eventToCHHistroy(historyEvent: chHistoryEvent) {
                        (self.delegate as? CHSesame2Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: [sesame2History])))
                    }
                    
                    self.postProcessHistory(histitem)
                    if isInternetReachable == true {
                        self.readHistoryCommand() { _ in }
                    }
                } else {
                    if result.cmdResultCode == .notFound {}
                    (self.delegate as? CHSesame2Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                }
            }
        }
    }
}

extension CHSesame2Device {
    func getHistories(cursor: UInt?, _ result: @escaping CHResult<CHSesameHistoryPayload>) {
        guard let getKey = getKey() else {
            // Key has been deleted
            return
        }
        let secretKey = getKey.secretKey.hexStringtoData()
        let sign = CC.CMAC.AESCMACWithTime(secretKey)
        var queryParams: [String: Any] = ["lg": 50, "a": sign[0...3].toHexString()]
        if let cursor = cursor {
            queryParams["cursor"] = cursor
        }
    }
    
    func postProcessHistory(_ historyData: Data) {}
}

public class CHSesame2HistoryData {
    required init(historyEvent: CHSesame2HistoryEvent) {
        self.recordID = historyEvent.recordID
        self.historyTag = historyEvent.historyTag
        self.date = Date(timeIntervalSince1970: TimeInterval(historyEvent.timeStamp/1000))
        self.timestamp = historyEvent.timeStamp
    }
    public  let recordID:Int32
    public  let historyTag: Data?
    public  let date: Date
    public let timestamp: UInt64
}


public class CHSesame2DriveFailedHistoryData: CHSesame2HistoryData {
    required init(historyEvent: CHSesame2HistoryEvent) {
        guard var stoppedPositionData = historyEvent.parameter![safeBound: 0...1],
              var fsmRetCodeData = historyEvent.parameter![safeBound: 2...2] else {
            stoppedPosition = 0
            fsmRetCode = 0
            deviceStatus = CHDeviceStatus.noSettings()
            super.init(historyEvent: historyEvent)
            return
        }
        self.stoppedPosition = stoppedPositionData.toInt16()
        self.fsmRetCode = fsmRetCodeData.toInt8()
        let flags: UInt8 = historyEvent.parameter![3]
//        L.d("flags!!!!!!!!!",flags)
        var isInLockRange: Bool { return flags & 1 > 0 }
        var isInUnlockRange: Bool { return flags & 2 > 0 }
        self.deviceStatus = isInLockRange  ? .locked() : isInUnlockRange  ? .unlocked() : .moved()
        super.init(historyEvent: historyEvent)
    }
    public var stoppedPosition: Int16
    public var fsmRetCode: Int8
    public var deviceStatus: CHDeviceStatus
}


public struct CHSesameHistoryPayload {
    public let histories: [CHSesame2History]
    public var cursor: UInt?
}

public struct CHSesame5HistoryPayload {
    public let histories: [CHSesame5History]
    public var cursor: UInt?
}

public enum CHSesame2History {

    case manualElse(CHSesame2HistoryData)
    case manualLocked(CHSesame2HistoryData)
    case manualUnlocked(CHSesame2HistoryData)
    case bleLock(CHSesame2HistoryData)
    case bleUnlock(CHSesame2HistoryData)
    case wm2Lock(CHSesame2HistoryData)
    case wm2Unlock(CHSesame2HistoryData)
    case webLock(CHSesame2HistoryData)
    case webUnlock(CHSesame2HistoryData)
    case autoLock(CHSesame2HistoryData)
    case driveLocked(CHSesame2HistoryData)
    case driveUnlocked(CHSesame2HistoryData)
    case driveClick(CHSesame2HistoryData)
    case manualClick(CHSesame2HistoryData)
    case bleClick(CHSesame2HistoryData)
    case wm2Click(CHSesame2HistoryData)
    case webClick(CHSesame2HistoryData)
    case driveFailed(CHSesame2DriveFailedHistoryData)
    case none(CHSesame2HistoryData)
}

extension CHSesame2Device {
    func eventToCHHistroy(historyEvent: CHSesame2HistoryEvent) -> CHSesame2History? {
        switch Sesame2HistoryTypeEnum(rawValue: historyEvent.type) {
        case .AUTOLOCK:
            return CHSesame2History.autoLock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .BLE_LOCK://
            return CHSesame2History.bleLock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .BLE_UNLOCK:
            return CHSesame2History.bleUnlock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WM2_LOCK:
            return CHSesame2History.wm2Lock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WM2_UNLOCK:
            return CHSesame2History.wm2Unlock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WEB_LOCK:
            return CHSesame2History.webLock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WEB_UNLOCK:
            return CHSesame2History.webUnlock(CHSesame2HistoryData(historyEvent: historyEvent))
        case .MANUAL_LOCKED:
            return CHSesame2History.manualLocked(CHSesame2HistoryData(historyEvent: historyEvent))
        case .MANUAL_UNLOCKED:
            return CHSesame2History.manualUnlocked(CHSesame2HistoryData(historyEvent: historyEvent))
        case .MANUAL_ELSE:
            return CHSesame2History.manualElse(CHSesame2HistoryData(historyEvent: historyEvent))
        case .NONE: // 錯誤
            return CHSesame2History.driveLocked(CHSesame2HistoryData(historyEvent: historyEvent))
        case .DRIVE_LOCKED:// 錯誤 馬達驅動到關閉
            return CHSesame2History.driveLocked(CHSesame2HistoryData(historyEvent: historyEvent))
        case .DRIVE_FAILED:
            return CHSesame2History.driveFailed(CHSesame2DriveFailedHistoryData(historyEvent: historyEvent))
        case .DRIVE_UNLOCKED:
            return CHSesame2History.driveUnlocked(CHSesame2HistoryData(historyEvent: historyEvent))
        case .BLE_CLICK:
            return CHSesame2History.bleClick(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WM2_CLICK:
            return CHSesame2History.wm2Click(CHSesame2HistoryData(historyEvent: historyEvent))
        case .WEB_CLICK:
            return CHSesame2History.webClick(CHSesame2HistoryData(historyEvent: historyEvent))
        case .DRIVE_CLICK:
            return CHSesame2History.driveClick(CHSesame2HistoryData(historyEvent: historyEvent))
        case .MANUAL_CLICK:
            return CHSesame2History.manualClick(CHSesame2HistoryData(historyEvent: historyEvent))
        case .none:
            return nil
        }
    }
}


