//
//  CHPassCodeCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation

public protocol CHPassCodeCapable: CHDevice ,CHSesameConnector, CHServerCapableHandler {
    
    func passCodes(result: @escaping(CHResult<CHEmpty>))
    func passCodeDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    // 即将废弃
    func passCodeChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func passCodeModeGet(result  : @escaping(CHResult<UInt8>))
    func passCodeModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
    func passCodeNameSet(passCodeNameRequest: CHKeyBoardPassCodeNameRequest, result: @escaping(CHResult<String>))
       
    func registerEventDelegate(_ delegate: CHPassCodeDelegate)
    
    func unregisterEventDelegate(_ delegate: CHPassCodeDelegate)
    
    func passCodeBatchAdd(data: Data, progressCallback: ((Int, Int) -> Void)?, result: @escaping (CHResult<CHEmpty>))
    
    func passCodeAdd(id: Data, name: String, result: @escaping (CHResult<CHEmpty>))
}
