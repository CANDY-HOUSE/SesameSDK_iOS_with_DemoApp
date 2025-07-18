//
//  CHSesameBikeDevice+Lock.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBikeDevice {
    public func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            L.d("📡 unlock by IoT")
            CHIoTManager.shared.sendCommandToWM2(.unlock,historytag ?? self.sesame2KeyData?.historyTag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            
            return
        }
        
        if (!self.isBleAvailable(result)) { return }
//        L.d("📡 unlock by ble")
        let tagCount_hisTag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        sendCommand(.init(.async, .unlock,tagCount_hisTag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

}
