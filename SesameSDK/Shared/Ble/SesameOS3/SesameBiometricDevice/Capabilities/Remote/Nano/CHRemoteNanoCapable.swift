//
//  CHRemoteNanoCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHRemoteNanoCapable :CHDevice{
    func setTriggerDelayTime(_ time: UInt8, result: @escaping(CHResult<CHEmpty>))
}
