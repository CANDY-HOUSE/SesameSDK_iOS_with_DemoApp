//
//  CHSwitchDevice+History.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBotDevice {

    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        if (self.checkBle(result)) { return }
        URLSession.isInternetReachable { isInternetReachable in
            let deleteHistory = isInternetReachable == true ? "01":"00"
            
            self.sendCommand(.init(.read, .history, deleteHistory.hexStringtoData())) { (result) in
                
                if result.cmdResultCode == .success {
                    
                    let histitem = result.data.copyData
                    
                    guard let recordId = histitem[safeBound: 0...3]?.copyData,
                          let type = histitem[safeBound: 4...4]?.copyData,
                          let timeData = histitem[safeBound: 5...12]?.copyData else {
                        return
                    }
                    let hisContent = histitem[13...].copyData
                    
                    let record_id_Int32: Int32 = recordId.withUnsafeBytes({ $0.bindMemory(to: Int32.self).first! })
                    let timestampInt64: UInt64 = timeData.withUnsafeBytes({ $0.bindMemory(to: UInt64.self).first! })
                    
                    guard var historyType: Sesame2HistoryTypeEnum = Sesame2HistoryTypeEnum(rawValue: type.bytes[0]) else {
                        return
                    }
                    
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
                    
                    //                    let chHistoryEvent = CHSesame2HistoryEvent(type: historyType,
                    //                                                               time: timestampInt64,
                    //                                                               recordID: record_id_Int32,
                    //                                                               content: historyContent)
                    //                    if let sesame2History = self.eventToCHHistroy(historyEvent: chHistoryEvent) {
                    //                        self.delegate?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: [sesame2History])))
                    //                    }
                    
                    //                    self.postProcessHistory(histitem)
                    if isInternetReachable == true {
                        self.readHistoryCommand() { _ in }
                    }
                } else {
                    //                    self.delegate?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                }
            }
        }
    }
    
    func postProcessHistory(_ historyData: Data) {
        let request: CHAPICallObject = .init(.post, "/device/v1/sesame2/historys", [
            "s": self.deviceId.uuidString,
            "v": historyData.toHexString()
        ])
        
        CHAccountManager
            .shared
            .API(request: request) { result in
                switch result {
                case .success(_): break
                    
                case .failure(let error):
                    L.d("上傳歷史失敗,掉歷史  : \(error)")
                }
            }
    }
}
