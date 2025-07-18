//
//  CHRemoteNanoCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHRemoteNanoCapable where Self: CHSesameOS3  {
    func setTriggerDelayTime(_ time: UInt8, result: @escaping(CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.REMOTE_NANO_ITEM_CODE_SET_TRIGGER_DELAYTIME, Data([time]))) { res in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
}
