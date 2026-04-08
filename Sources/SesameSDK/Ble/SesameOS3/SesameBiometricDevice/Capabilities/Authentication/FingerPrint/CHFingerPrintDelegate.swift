//
//  CHFingerPrintDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHFingerPrintDelegate: AnyObject {
    
    func onFingerPrintReceiveStart(device: CHDevice)
    func onFingerPrintReceiveEnd(device: CHDevice)
    func onFingerPrintReceive(device: CHDevice, id: String, hexName: String, type: UInt8)
    func onFingerPrintChanged(device: CHDevice, id: String, hexName: String, type: UInt8)
    func onFingerModeChange(mode: UInt8)
    func onFingerPrintDelete(device: CHDevice, id: String)
    
}


public extension CHFingerPrintDelegate {
    func onFingerPrintReceiveStart(device: CHDevice){}
    func onFingerPrintReceiveEnd(device: CHDevice){}
    func onFingerPrintReceive(device: CHDevice, id: String, hexName: String, type: UInt8){}
    func onFingerPrintChanged(device: CHDevice, id: String, hexName: String, type: UInt8){}
    func onFingerModeChange(mode: UInt8){}
    func onFingerPrintDelete(device: CHDevice, id: String){}
}

