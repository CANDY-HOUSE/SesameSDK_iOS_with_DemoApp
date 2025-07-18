//
//  CHPassCodeDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


public protocol CHPassCodeDelegate: AnyObject {
    func onPassCodeReceiveStart(device: CHSesameConnector)
    func onPassCodeReceiveEnd(device: CHSesameConnector)
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onPassCodeModeChanged(mode: UInt8)
    func onPassCodeDelete(device: CHSesameConnector, id: String)
}


public extension CHPassCodeDelegate {
    func onPassCodeReceiveStart(device: CHSesameConnector){}
    func onPassCodeReceiveEnd(device: CHSesameConnector){}
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onPassCodeModeChanged(mode: UInt8){}
    func onPassCodeDelete(device: CHSesameConnector, passCodeId: String){}
}

