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
                    let histItem = result.data.copyData
                    (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: histItem)))
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
