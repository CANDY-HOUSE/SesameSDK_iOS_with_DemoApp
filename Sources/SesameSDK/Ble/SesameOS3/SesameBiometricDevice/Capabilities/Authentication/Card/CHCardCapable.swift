//
//  CHCardCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

public protocol CHCardCapable: CHDevice ,CHSesameConnector, CHServerCapableHandler {
    
    func cards(result: @escaping(CHResult<CHEmpty>))
    func cardDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    // 即将废弃
    func cardsChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func cardsModeGet(result  : @escaping(CHResult<UInt8>))
    func cardsModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
    func cardNameSet(cardNameRequest: CHCardNameRequest, result: @escaping(CHResult<String>))
    
    func registerEventDelegate(_ delegate: CHCardDelegate)
    func unregisterEventDelegate(_ delegate: CHCardDelegate)
    
    func cardAdd(id: Data, name: String, result: @escaping (CHResult<CHEmpty>))
    func cardBatchAdd(data: Data, progressCallback: ((Int, Int) -> Void)?, result: @escaping (CHResult<CHEmpty>))
}
