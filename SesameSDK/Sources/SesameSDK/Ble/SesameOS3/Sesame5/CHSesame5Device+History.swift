//
//  CHSesame5Device+History.swift
//  SesameSDK
//  [history]read/get/post
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesame5Device {
    
    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        L.d("[ss5][history] readHistoryCommand <=")
        URLSession.isInternetReachable { isInternetReachable in
//            L.d("[ss5][history] 連網?",isInternetReachable)
            self.sendCommand(.init( .history, "01".hexStringtoData())) { (result) in // 01: 从设备读取最旧的历史记录
                if result.cmdResultCode == .success {
                    guard isInternetReachable && !self.isConnectedByWM2 else { return }
                    self.postProcessHistory(result.data.copyData) { res in
                        if case .success(_) = res  {
                            let recordId = result.data.copyData[0...3].copyData
                            self.sendCommand(.init(SesameItemCode.historyDelete, recordId)) { response in
                                if response.cmdResultCode == .success  { L.d("[ss5][history]歷史删除成功") }
                            }
                        }
                    }
                } else {
                    (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }
}

extension CHSesame5Device {
    
    func getHistories(cursor: UInt?, subUUID: String?, _ result: @escaping CHResult<CHSesame5HistoryPayload>) {
//        L.d("[ss5][history] getHistories")
        guard let getKey = getKey() else {
            // Key has been deleted
            return
        }
        let secretKey = getKey.sesame2PublicKey
        var queryParams: [String: Any] = ["lg": 15, "a": secretKey, "subUUID": subUUID ?? ""]
        if let cursor = cursor {
            queryParams["cursor"] = cursor
        }
        CHAccountManager.shared
            .API(request: .init(.get, "/device/v2/sesame2/\(self.deviceId.uuidString)/history", queryParameters: queryParams)) { requestResult in

                switch requestResult {
                case .success(let data):
                    //                    L.d("[ss5][history]",data)
                    guard let historyResponse = try? JSONDecoder().decode(CHSesameHistory5Response.self, from: data ?? Data()) else {
                        result(.failure(NSError.parseError))
                        return
                    }
                    let sesame2Histories = historyResponse.histories.compactMap { self.eventToCHHistroy( historyEvent: $0) }
                    result(.success(CHResultStateNetworks(input: .init(histories: sesame2Histories, cursor: historyResponse.cursor))))
                case .failure(let error):
                    result(.failure(error))
                }
            }
    }
    
    func postProcessHistory(_ historyData: Data, _ callback: @escaping CHResult<CHEmpty>) {
//        L.d("[ss5][history]post")
        let request: CHAPICallObject = .init(.post, "/device/v1/sesame2/historys", [
            "s": self.deviceId.uuidString,
            "v": historyData.toHexString(),
            "t":"5",
        ])

        CHAccountManager
            .shared
            .API(request: request) { result in
                switch result {
                case .success(_):
                    L.d("[ss5][history]藍芽", "上傳歷史成功")
                    callback(.success(CHResultStateNetworks(input:CHEmpty())))
                    break
                case .failure(let error):
                    L.d("[ss5][history]藍芽", "上傳歷史失敗,server掉歷史: \(error)")
                    callback(.failure(error))
                    break
                }
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
    case webLock(CHSesame5HistoryData)
    case webUnlock(CHSesame5HistoryData)
    case doorOpen(CHSesame5HistoryData)
    case doorClose(CHSesame5HistoryData)

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
        case .WEB_LOCK:
            return CHSesame5History.webLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WEB_UNLOCK:
            return CHSesame5History.webUnlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .DOOR_OPEN:
            return CHSesame5History.doorOpen(CHSesame5HistoryData(historyEvent: historyEvent))
        case .DOOR_CLOSE:
            return CHSesame5History.doorClose(CHSesame5HistoryData(historyEvent: historyEvent))
        @unknown default:
            return nil
        }
    }
}
