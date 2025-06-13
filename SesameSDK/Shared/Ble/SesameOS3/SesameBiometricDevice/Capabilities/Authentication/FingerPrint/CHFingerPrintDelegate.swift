//
//  CHFingerPrintDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHFingerPrintDelegate: AnyObject {
    
    func onFingerPrintReceiveStart(device: CHSesameConnector)
    func onFingerPrintReceiveEnd(device: CHSesameConnector)
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onFingerModeChange(mode: UInt8)
    func onFingerPrintDelete(device: CHSesameConnector, id: String)
    
}


public extension CHFingerPrintDelegate {
    func onFingerPrintReceiveStart(device: CHSesameConnector){}
    func onFingerPrintReceiveEnd(device: CHSesameConnector){}
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onFingerModeChange(mode: UInt8){}
    func onFingerPrintDelete(device: CHSesameConnector, id: String){}
}

