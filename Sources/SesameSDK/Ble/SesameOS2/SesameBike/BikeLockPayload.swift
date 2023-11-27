//
//  BikeLockPayload.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

// MARK: - Payload
public struct CHSesameBikeMechSettings {
    public  var secs: BikeLockUnlockSecs
    public  var padding1: UInt8 = 0
    public  var padding2: UInt16 = 0
    public var padding3: UInt16 = 0
    public var padding4: UInt16 = 0
    public var padding5: UInt16 = 0
    
    public var unlockSecs: CHSesameBikeUnlockSecs {
        CHSesameBikeUnlockSecs(forward: Float(secs.forward) / 10.0,
                             hold: Float(secs.hold) / 10.0,
                             backward: Float(secs.backward) / 10.0)
    }

    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBikeMechSettings>.size)
    }
    
    static func fromData(_ buf: Data) -> CHSesameBikeMechSettings? {
        return to(buf)
    }

    func isConfigured() -> Bool {
        return true
    }
}

struct BikeLockMechStatus: CHSesameProtocolMechStatus {

    let battery: UInt16
    let target: Int16    // Padding, no usage
    let padding2: Int16
    let retCode: UInt8   // 0或1, 1表示Bike完成unlock動作(經由BLE command及手動)及lock動作(只能經由手動),有新的history產生
    let flags: UInt8     // bit0 : isMoving, bit1 : isInLockRange, bit2 : isInUnlockRange

    var isMoving: Bool { return flags & 1 > 0 }
    var isInLockRange: Bool { return flags & 2 > 0 }
    var isInUnlockRange: Bool { return flags & 4 > 0 }
    var isStop: Bool? { return flags & 1 == 0 }
    var isBatteryCritical: Bool { return false }
    var position: Int16 {
        0
    }                   // Padding, no usage
    var data: Data {
        battery.data + target.data + padding2.data + retCode.data + flags.data
    }
    
   

    public func getBatteryVoltage() -> Float {
        return Float(battery) * 7.2 / 1023
    }
    
    var isClutchFailed: Bool {
        return false
    }

    static func fromData(_ buf: Data) -> BikeLockMechStatus? {
        return to(buf)
    }
}

// MARK: - Response
struct BikeLockLoginResponsePayload {
    var systemTime: UInt32
    var fwVersion: UInt8
    var userCnt: UInt8
    var historyCnt: UInt8
    var flags: UInt8
    var mechSetting: CHSesameBikeMechSettings
    var mechStatus: BikeLockMechStatus

    static func fromData(_ buf: Data) -> BikeLockLoginResponsePayload? {
        if buf.count == 30 {
            //TODO For bad payload with autolock
            let offset = buf.indices.lowerBound
            let newBuf = buf[offset...offset + 7] + buf[offset + 10...offset + 29]
            return to(newBuf)
        }
        return to(buf)
    }

    func bikeLockTimeFromNowTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970) - Int64(systemTime)
    }
}

public struct CHSesameBikeUnlockSecs {
    public private(set) var forward: Float
    public private(set) var hold: Float
    public private(set) var backward: Float
    
    public init(forward: Float, hold: Float, backward: Float) {
        self.forward = forward
        self.hold = hold
        self.backward = backward
    }
    
    static func fromData(_ buf: Data) -> CHSesameBikeUnlockSecs? {
        return to(buf)
    }
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBikeUnlockSecs>.size)
    }
}

public struct BikeLockUnlockSecs {
    public   var forward: UInt8  // 單位為0.1秒,預設值為10,代表1秒 ,為進行解鎖時,馬達進行1之3動作,往前轉的時間
    public   var hold: UInt8     // 單位為0.1秒,預設值為2,代表0.2秒,為進行解鎖時,馬達進行2之3動作,原地不動的時間
    public  var backward: UInt8 // 單位為0.1秒,預設值為10,代表1秒 ,為進行解鎖時，馬達進行3之3動作,往後轉的時間
    
    static func fromData(_ buf: Data) -> BikeLockUnlockSecs? {
        return to(buf)
    }
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<BikeLockUnlockSecs>.size)
    }
}
