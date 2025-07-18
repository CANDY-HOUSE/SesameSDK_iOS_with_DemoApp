//
//  CHFaceDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHFaceDelegate: AnyObject {
    
    func onFaceReceiveStart(device: CHSesameConnector)
    func onFaceReceiveEnd(device: CHSesameConnector)
    func onFaceReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onFaceChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onFaceModeChanged(mode: UInt8)
    func onFaceDeleted(faceId: UInt8,isSuccess:Bool)
}


public extension CHFaceDelegate {
    
    func onFaceReceiveStart(device: CHSesameConnector){}
    func onFaceReceiveEnd(device: CHSesameConnector){}
    func onFaceReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onFaceChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onFaceModeChanged(mode: UInt8){}
    func onFaceDeleted(faceId: UInt8,isSuccess:Bool){}
}

