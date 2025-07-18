//
//  CHCapbleRenameBean.swift
//  SesameSDK
//
//  Created by wuying on 2025/5/27.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
public struct CHCardNameRequest: Codable {
    public let cardType: UInt8
    public let cardNameUUID: String
    public let subUUID: String
    public let stpDeviceUUID: String
    public let name: String
    public let cardID: String
    public let timestamp: Int64
    
    public init(cardType: UInt8, cardNameUUID: String, subUUID: String, stpDeviceUUID: String, name: String, cardID: String) {
        self.cardType = cardType
        self.cardNameUUID = cardNameUUID
        self.subUUID = subUUID
        self.stpDeviceUUID = stpDeviceUUID
        self.name = name
        self.cardID = cardID
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000) // 毫秒时间戳
    }
}


public struct CHFaceNameRequest: Codable {
    public let type: Int8
    public let faceNameUUID: String
    public let subUUID: String
    public let stpDeviceUUID: String
    public let name: String
    public let faceID: String
    public let timestamp: Int64
    
    public init(type: Int8, faceNameUUID: String, subUUID: String, stpDeviceUUID: String, name: String, faceID: String) {
        self.type = type
        self.faceNameUUID = faceNameUUID
        self.subUUID = subUUID
        self.stpDeviceUUID = stpDeviceUUID
        self.name = name
        self.faceID = faceID
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000) // 毫秒时间戳
    }
}


public struct CHFingerPrintNameRequest: Codable {
    public let type: Int8
    public let fingerPrintNameUUID: String
    public let subUUID: String
    public let stpDeviceUUID: String
    public let name: String
    public let fingerPrintID: String
    public let timestamp: Int64
    
    public init(type: Int8, fingerPrintNameUUID: String, subUUID: String, stpDeviceUUID: String, name: String, fingerPrintID: String) {
        self.type = type
        self.fingerPrintNameUUID = fingerPrintNameUUID
        self.subUUID = subUUID
        self.stpDeviceUUID = stpDeviceUUID
        self.name = name
        self.fingerPrintID = fingerPrintID
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000) // 毫秒时间戳
    }
}


public struct CHPalmNameRequest: Codable {
    public let type: Int8
    public let palmNameUUID: String
    public let subUUID: String
    public let stpDeviceUUID: String
    public let name: String
    public let palmID: String
    public let timestamp: Int64
    
    public init(type: Int8, palmNameUUID: String, subUUID: String, stpDeviceUUID: String, name: String, palmID: String) {
        self.type = type
        self.palmNameUUID = palmNameUUID
        self.subUUID = subUUID
        self.stpDeviceUUID = stpDeviceUUID
        self.name = name
        self.palmID = palmID
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000) // 毫秒时间戳
    }
}


public struct CHKeyBoardPassCodeNameRequest: Codable {
    public let type: Int8
    public let keyBoardPassCodeNameUUID: String
    public let subUUID: String
    public let stpDeviceUUID: String
    public let name: String
    public let keyBoardPassCode: String
    public let timestamp: Int64
    
    public init(type: Int8, keyBoardPassCodeNameUUID: String, subUUID: String, stpDeviceUUID: String, name: String, keyBoardPassCode: String) {
        self.type = type
        self.keyBoardPassCodeNameUUID = keyBoardPassCodeNameUUID
        self.subUUID = subUUID
        self.stpDeviceUUID = stpDeviceUUID
        self.name = name
        self.keyBoardPassCode = keyBoardPassCode
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000) // 毫秒时间戳
    }
}
