//
//  CHPalmCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHPalmCapable: CHDevice ,CHSesameConnector {
    
    func palms(result: @escaping(CHResult<CHEmpty>))
    func palmDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    func palmModeGet(result  : @escaping(CHResult<UInt8>))
    func palmModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
        
    func registerEventDelegate(_ delegate: CHPalmDelegate)
    func unregisterEventDelegate(_ delegate: CHPalmDelegate)
    
}
