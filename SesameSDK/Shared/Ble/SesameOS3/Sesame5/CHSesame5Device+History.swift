//
//  CHSesame5Device+History.swift
//  SesameSDK
//  [history]read/get/post
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

extension CHSesame5Device {
    
    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
            self.sendCommand(.init( .history, "00".hexStringtoData())) { (result) in
                if result.cmdResultCode == .success {
                    let histitem = result.data.copyData
                    let recordId = histitem[0...3].copyData
                    let type = histitem[4...4].copyData
                    let timeData = histitem[5...8].copyData
                    let mechStatusData = histitem[9...15].copyData
                    var hisContent = histitem[16...].copyData // historyTag
                    var historyType: Sesame2HistoryTypeEnum = Sesame2HistoryTypeEnum(rawValue: type.bytes[0])!
                    let record_id_Int32: Int32 = recordId.withUnsafeBytes({ $0.bindMemory(to: Int32.self).first! })
                    let timestampInt32: UInt32 = timeData.withUnsafeBytes({ $0.bindMemory(to: UInt32.self).first! })
                    
                    if(historyType == .BLE_LOCK){
                        guard hisContent.count > 0 else {
                            hisContent = Data()
                            return
                        }
                        let tagcount = UInt8(hisContent[0]) 
                        let originalTagCount = tagcount % Sesame2HistoryLockOpType.BASE.rawValue
                        
                        let historyOpType = Sesame2HistoryLockOpType(rawValue: tagcount / Sesame2HistoryLockOpType.BASE.rawValue)
                        if  historyOpType == .WM2 {
                            historyType = Sesame2HistoryTypeEnum.WM2_LOCK
                        }
                        guard hisContent.count > originalTagCount else { return }
                        hisContent = originalTagCount.data + hisContent[1...originalTagCount].copyData
                    }
                    
                    if(historyType == .BLE_UNLOCK){
                        guard hisContent.count > 0 else {
                            hisContent = Data()
                            return
                        }
                        let tagcount = UInt8(hisContent[0])
                        let originalTagCount = tagcount % Sesame2HistoryLockOpType.BASE.rawValue
                        let historyOpType = Sesame2HistoryLockOpType(rawValue: tagcount / Sesame2HistoryLockOpType.BASE.rawValue)
                        if  historyOpType == .WM2 {
                            historyType = Sesame2HistoryTypeEnum.WM2_UNLOCK
                        }
                        guard hisContent.count > originalTagCount else { return }
                        hisContent = originalTagCount.data + hisContent[1...originalTagCount].copyData
                    }

                    let chHistoryEvent = CHSesame5HistoryEvent(type:historyType,time:UInt64(timestampInt32)*1000,recordID:record_id_Int32,content:hisContent,parameter:mechStatusData) // Event用在post
                    let sesame2History = self.eventToCHHistroy(historyEvent: chHistoryEvent)!
                    (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: [sesame2History])))
                    if( self.isHistory){
                        self.readHistoryCommand() { _ in }
                    }

                }else{
                    (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }

extension CHSesame5Device {
    func getHistories(cursor: UInt?, _ result: @escaping CHResult<CHSesame5HistoryPayload>) {
        guard let getKey = getKey() else {
            // Key has been deleted
            return
        }
    }
}

public class CHSesame5HistoryData {
    required init(historyEvent: CHSesame5HistoryEvent) {
        self.recordID = historyEvent.recordID
        self.historyTag = historyEvent.historyTag
        self.date = Date(timeIntervalSince1970: TimeInterval(historyEvent.timeStamp/1000))
        self.timestamp = historyEvent.timeStamp
        self.mechStatus = historyEvent.parameter == nil ? nil : Sesame5MechStatus.fromData(historyEvent.parameter!)
    }
    
    public let recordID:Int32
    public let historyTag: Data?
    public let date: Date
    public let timestamp: UInt64
    public let mechStatus: CHSesameProtocolMechStatus?
}

public enum CHSesame5History {
    case manualLocked(CHSesame5HistoryData)
    case manualUnlocked(CHSesame5HistoryData)
    case bleLock(CHSesame5HistoryData)
    case bleUnlock(CHSesame5HistoryData)
    case autoLock(CHSesame5HistoryData)
    case wm2Lock(CHSesame5HistoryData)
    case wm2Unlock(CHSesame5HistoryData)
}

extension CHSesame5Device {
    func eventToCHHistroy(historyEvent: CHSesame5HistoryEvent) -> CHSesame5History? {
        switch Sesame2HistoryTypeEnum(rawValue: historyEvent.type) {
        case .AUTOLOCK:
            return CHSesame5History.autoLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .BLE_LOCK:
            return CHSesame5History.bleLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .BLE_UNLOCK:
            return CHSesame5History.bleUnlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WM2_UNLOCK:
            return CHSesame5History.wm2Unlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WM2_LOCK:
            return CHSesame5History.wm2Lock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .MANUAL_LOCKED:
            return CHSesame5History.manualLocked(CHSesame5HistoryData(historyEvent: historyEvent))
        case .MANUAL_UNLOCKED:
            return CHSesame5History.manualUnlocked(CHSesame5HistoryData(historyEvent: historyEvent))
//        case .WEB_LOCK:
//            return CHSesame5History.wm2Lock(CHSesame5HistoryData(historyEvent: historyEvent))
//        case .WEB_UNLOCK:
//            return CHSesame5History.wm2Unlock(CHSesame5HistoryData(historyEvent: historyEvent))
        @unknown default:
            return nil
        }
    }
}
