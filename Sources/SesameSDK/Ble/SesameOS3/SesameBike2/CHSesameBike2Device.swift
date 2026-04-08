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
            if data.count == 7 {
                mechStatus = Sesame5MechStatus.fromData(data)!
            } else {
                mechStatus = CHSesameBike2MechStatus.fromData(data)!
            }
            self.deviceStatus = mechStatus!.isInLockRange ? .locked() : .unlocked()
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
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
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
