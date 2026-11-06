//
//  CHSesameBike2Device.swift
//  SesameSDK
//
//  Created by JOi Chao on 2023/5/30.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBike2Device: CHSesameOS3LockBase, CHSesameBike2 {
    
    override func handleLockDevicePublish(_ payload: SesameOS3PublishPayload) {
        let itemCode = payload.itemCode
        let data = payload.payload
        
        switch itemCode {
        case .mechStatus:
            let parsed: CHSesameProtocolMechStatus? = data.count == 7 ? Sesame5MechStatus.fromData(data) : CHSesameBike2MechStatus.fromData(data)
            guard let status = parsed else { return }
            mechStatus = status
            self.deviceStatus = status.isInLockRange ? .locked() : .unlocked()
            postBatteryData(data[0..<2].toHexString()) { res in
                if case .success(let resp) = res {
                    self.notifyBatteryPercentageChanged(percentage: resp.data)
                }
            }
            
        default:
            L.d("[bk2][publish]!![\(itemCode.rawValue)]")
        }
    }
    
    override func notifyHistoryReceived(_ result: Result<CHResultState<Data>, Error>) {
        (self.delegate as? CHSesameBike2Delegate)?.onHistoryReceived(device: self, result: result)
    }
}

extension CHSesameBike2Device {
    
    public func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.unlock,historytag)) { responsePayload in
            //L.d("[bk2][unlock][sendCommand] res =>",responsePayload.cmdResultCode)
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
}
