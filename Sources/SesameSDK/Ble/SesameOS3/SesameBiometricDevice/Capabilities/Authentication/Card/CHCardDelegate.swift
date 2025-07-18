//
//  CHCardDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//



public protocol CHCardDelegate: AnyObject {
    
    func onCardReceiveStart(device: CHSesameConnector)
    func onCardReceiveEnd(device: CHSesameConnector)
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onCardModeChanged(mode: UInt8)
    func onCardDelete(device: CHSesameConnector, id: String)
}

public extension  CHCardDelegate {
    func onCardReceiveStart(device: CHSesameConnector){}
    func onCardReceiveEnd(device: CHSesameConnector){}
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onCardModeChanged(mode: UInt8){}
    func onCardReceive(device: CHSesameConnector, id: String) {}
}
