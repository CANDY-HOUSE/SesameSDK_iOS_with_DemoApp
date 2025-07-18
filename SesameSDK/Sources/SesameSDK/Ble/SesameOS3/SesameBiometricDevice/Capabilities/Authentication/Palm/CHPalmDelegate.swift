//
//  CHPalmDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHPalmDelegate: AnyObject {
    func onPalmReceiveStart(device: CHSesameConnector)
    func onPalmReceiveEnd(device: CHSesameConnector)
    func onPalmReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onPalmChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onPalmModeChanged(mode: UInt8)
    func onPalmDeleted(palmId: UInt8,isSuccess:Bool)
    
}

public extension  CHPalmDelegate {
    func onPalmReceiveStart(device: CHSesameConnector){}
    func onPalmReceiveEnd(device: CHSesameConnector){}
    func onPalmReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onPalmChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onPalmModeChanged(mode: UInt8){}
    func onPalmDeleted(palmId: UInt8,isSuccess:Bool){}
}

