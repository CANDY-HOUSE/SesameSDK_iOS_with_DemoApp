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
        if (!self.isBleAvailable(result)) { return }
//        L.d("🌇 讀取歷史")
        do {
            let isInternetReachable = CHBleSupport.host.isNetworkAvailable()
            let deleteHistory = isInternetReachable == true ? "01":"00"
            
            self.sendCommand(.init(.read, .history, deleteHistory.hexStringtoData())) { (result) in
                
                if result.cmdResultCode == .success {
                    
//                    let histitem = result.data.copyData
                   
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
        CHBleSupport.host.postHistory(deviceId: deviceId, historyHex: historyData.toHexString(), os3: false) { _ in }
    }
}
