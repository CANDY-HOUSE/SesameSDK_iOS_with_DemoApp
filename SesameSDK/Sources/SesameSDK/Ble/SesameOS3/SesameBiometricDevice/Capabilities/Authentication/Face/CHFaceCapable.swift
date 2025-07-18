//
//  CHFaceCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHFaceCapable: CHDevice, CHServerCapableHandler {
    
    func faces(result: @escaping(CHResult<CHEmpty>))
    func faceDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    func faceModeGet(result  : @escaping(CHResult<UInt8>))
    func faceModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
    func faceNameSet(faceNameRequest: CHFaceNameRequest, result: @escaping(CHResult<String>))
    
    func registerEventDelegate(_ delegate: CHFaceDelegate)
    func unregisterEventDelegate(_ delegate: CHFaceDelegate)
    
}
