//
//  Sesame2BleDevice+History.swift
//  Sesame2SDK
//
//  Created by Tse on 2019/10/07.
//  Copyright © 2019 Candyhouse. All rights reserved.
//
import Foundation
extension CHSesame2Device {

    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        if !self.isBleAvailable(result) {
//            L.d("藍芽", "藍芽檢查錯誤")
            return
        }
        guard let fwVersion = fwVersion, fwVersion > 0 else {
//            L.d("藍芽", "版本==0")
            return
        }
        URLSession.isInternetReachable { isInternetReachable in
            let deleteHistory = isInternetReachable == true ? "01":"00"
            self.sendCommand(.init(.read, .history, deleteHistory.hexStringtoData())) { (result) in
                if result.cmdResultCode == .success {
                    let histItem = result.data.copyData
                    (self.delegate as? CHSesame2Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: histItem)))
                    self.postProcessHistory(histItem)
                    if isInternetReachable == true {
    //                    L.d("藍芽", "有網路繼續讀歷史")
                        self.readHistoryCommand() { _ in }
                    }
                } else {
                    if result.cmdResultCode == .notFound {
    //                    L.d("藍芽", "RESPONSE", "沒歷史", self.errorFromResultCode(result.cmdResultCode))
                    }
                    (self.delegate as? CHSesame2Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                }
            }
        }
    }
}

extension CHSesame2Device {
    func postProcessHistory(_ historyData: Data) {
//        L.d("postProcessHistory =>")
        let request: CHAPICallObject = .init(.post, "/device/v1/sesame2/historys", [
            "s": self.deviceId.uuidString,
            "v": historyData.toHexString()
        ])
        
        CHAccountManager
            .shared
            .API(request: request) { result in
                switch result {
                case .success(_):
                    L.d("藍芽", "上傳歷史成功")
                    break
                case .failure(let error):
                    L.d("藍芽", "上傳歷史失敗,掉歷史  : \(error)")
                    break
            }
        }
    }
}

