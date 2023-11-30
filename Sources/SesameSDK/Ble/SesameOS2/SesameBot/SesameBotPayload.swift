//
//  SesameBotPayload.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

// MARK: - Payload
public struct CHSesameBotMechSettings {
    public var userPrefDir: CHSesameBotUserPreDir
    public var lockSecConfig: CHSesameBotLockSecondsConfiguration
    public var buttonMode: CHSesameBotButtonMode
    var padding1: UInt8 = 0
    var padding2: Int16 = 0
    var padding3: Int16 = 0
    
    static func fromData(_ buf: Data) -> CHSesameBotMechSettings? {
        return to(buf)
    }
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBotMechSettings>.size)
    }

    public func isConfigured() -> Bool {
        return true
    }
}

struct SesameBotMechStatus: CHSesameProtocolMechStatus {
    
    let battery: UInt16
    let position: Int16    // Padding, no usage
    let motorStatus: UInt8 // noPower: 0, forward: 1, hold:2, backward: 3
    let padding2: UInt8
    let retCode: UInt8     // 0, 1
    var flags: UInt8       // bit1:in_lock_range, bit0:in_unlock_range, other bit: unused
    var target: Int16 {
        0
    }                      // padding no usage
    var data: Data {
        battery.data + position.data + motorStatus.data + padding2.data + retCode.data + flags.data
    }
    var isClutchFailed: Bool {return flags & 1 > 0}
    var isInLockRange: Bool {return flags & 2 > 0}
    var isInUnlockRange: Bool {return flags & 4 > 0}
    var isStop: Bool?{motorStatus == 0}
    var isMoving: Bool { motorStatus != 0 }
    var isBatteryCritical: Bool { return false }
    
 

//    
    func getBatteryVoltage() -> Float {
        return Float(battery) * 7.2 / 1023
    }

    static func fromData(_ buf: Data) -> SesameBotMechStatus? {
        return to(buf)
    }
}

// MARK: - Response
struct SesameBotLoginResponsePayload {
    var systemTime: UInt32
    var fwVersion: UInt8
    var userCnt: UInt8
    var historyCnt: UInt8
    var flags: UInt8
    var mechSetting: CHSesameBotMechSettings
    var mechStatus: SesameBotMechStatus

    static func fromData(_ buf: Data) -> SesameBotLoginResponsePayload? {
        if buf.count == 30 {
            //TODO For bad payload with autolock
            let offset = buf.indices.lowerBound
            let newBuf = buf[offset...offset + 7] + buf[offset + 10...offset + 29]
            return to(newBuf)
        }
        return to(buf)
    }

    func switchTimeFromNowTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970) - Int64(systemTime)
    }
}

struct CHSesameBotFICR {
    var ir: String
    var er: String

    static func fromData(_ buf: Data) -> CHSesameBotFICR? {
        let copy = buf.copyData
        let ir = copy[0...15].toHexString()
        let er = copy[16...].toHexString()
        return CHSesameBotFICR(ir: ir, er: er)
    }
}

struct CHSesameBotClickSeconds {
    public init(clickLockSecond: Float, clickHoldSecond: Float, clickUnlockSecond: Float) {
        self.clickLockSecond = clickLockSecond
        self.clickHoldSecond = clickHoldSecond
        self.clickUnlockSecond = clickUnlockSecond
    }
    
    public let clickLockSecond: Float
    public let clickHoldSecond: Float
    public let clickUnlockSecond: Float
}
