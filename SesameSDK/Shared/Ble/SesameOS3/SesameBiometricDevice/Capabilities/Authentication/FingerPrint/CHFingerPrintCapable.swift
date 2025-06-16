//
//  CHFingerPrintCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHFingerPrintCapable: CHDevice ,CHSesameConnector, CHServerCapableHandler {
    
    func fingerPrints(result: @escaping(CHResult<CHEmpty>))
    func fingerPrintDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    // 即将废弃
    func fingerPrintsChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func fingerPrintModeGet(result  : @escaping(CHResult<UInt8>))
    func fingerPrintModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
    func fingerPrintNameSet(fingerPrintNameRequest: CHFingerPrintNameRequest, result: @escaping(CHResult<String>))
    
    func registerEventDelegate(_ delegate: CHFingerPrintDelegate)
    func unregisterEventDelegate(_ delegate: CHFingerPrintDelegate)
    
}
