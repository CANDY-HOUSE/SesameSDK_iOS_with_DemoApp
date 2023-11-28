//
//  Sesame2Protocols.swift
//  SesameSDK
//
//  Created by tse on 2020/8/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation


struct CHSesame2LockPositionConfiguration {
    var lockTarget: Int16
    var unlockTarget: Int16
    var lockRangeMin: Int16
    var lockRangeMax: Int16
    var unlockRangeMin: Int16
    var unlockRangeMax: Int16

    init(lockTarget: Int16, unlockTarget: Int16, interval: Int16 = 150) {
        self.lockTarget = lockTarget
        self.lockRangeMin = lockTarget - interval
        self.lockRangeMax = lockTarget + interval
        self.unlockTarget = unlockTarget
        self.unlockRangeMin = unlockTarget - interval
        self.unlockRangeMax = unlockTarget + interval
    }

    init(lockTarget: Int16, unlockTarget: Int16, lockRangeMin: Int16, lockRangeMax: Int16, unlockRangeMin: Int16, unlockRangeMax: Int16) {
        self.lockTarget = lockTarget
        self.unlockTarget = unlockTarget
        self.lockRangeMin = lockRangeMin
        self.lockRangeMax = lockRangeMax
        self.unlockRangeMin = unlockRangeMin
        self.unlockRangeMax = unlockRangeMax
    }

    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesame2LockPositionConfiguration>.size)
    }
}





enum Sesame2OpCode: UInt8, CustomStringConvertible {
    case create   = 0x01
    case read     = 0x02
    case update   = 0x03
    case delete   = 0x04
    case sync     = 0x05
    case async    = 0x06
    case response = 0x07
    case publish  = 0x08
    case undefine = 0x10

    var description: String {
        return String(format: "opCode:0x%x", self.rawValue)
    }
}

extension Sesame2OpCode {

    /// Describable `Sesame2OpCode`
    var plainName: String {
        switch self {
        case .create:
            return "create"
        case .read:
            return "read"
        case .update:
            return "update"
        case .delete:
            return "delete"
        case .sync:
            return "sync"
        case .async:
            return "async"
        case .response:
            return "response"
        case .publish:
            return "publish"
        case .undefine:
            return "undefine"
        }
    }
}

enum Sesame2HistoryTypeEnum:UInt8
{
    case NONE = 0
    // Trigger by BLE
    case BLE_LOCK = 1
    case BLE_UNLOCK = 2
//    case TIME_CHANGED = 3
//    case AUTOLOCK_UPDATED = 4
//    case MECH_SETTING_UPDATED = 5
    // Trigger by INTERNAL
    case AUTOLOCK = 6
    // Trigger by SENSOR/MOTOR when detected stopped state
    case MANUAL_LOCKED = 7
    case MANUAL_UNLOCKED = 8
    case MANUAL_ELSE = 9
    case DRIVE_LOCKED = 10
    case DRIVE_UNLOCKED = 11
    case DRIVE_FAILED = 12
//    case BLE_ADV_PARAM_UPDATED = 13
    case WM2_LOCK = 14
    case WM2_UNLOCK = 15
    case WEB_LOCK = 16
    case WEB_UNLOCK = 17
    
    case BLE_CLICK = 18
    case WM2_CLICK = 19             // Server, client解析用
    case WEB_CLICK = 20              // Server, client解析用
    case DRIVE_CLICK = 21
    case MANUAL_CLICK = 22
}

enum Sesame2HistoryLockOpType: UInt8 {
    case BLE = 0
    case WM2 = 1
    case WEB = 2
    case BASE = 30
}

extension Sesame2HistoryTypeEnum {

    var plainName: String {
        switch self {

        case .NONE:
            return "NONE"
        case .BLE_LOCK:
            return "BLE_LOCK"
        case .BLE_UNLOCK:
            return "BLE_UNLOCK"
        case .AUTOLOCK:
            return "AUTOLOCK"
        case .MANUAL_LOCKED:
            return "MANUAL_LOCKED"
        case .MANUAL_UNLOCKED:
            return "MANUAL_UNLOCKED"
        case .MANUAL_ELSE:
            return "MANUAL_ELSE"
        case .DRIVE_LOCKED:
            return "DRIVE_LOCKED"
        case .DRIVE_UNLOCKED:
            return "DRIVE_UNLOCKED"
        case .DRIVE_FAILED:
            return "DRIVE_FAILED"
        case .WM2_LOCK:
            return "WM2_LOCK"
        case .WM2_UNLOCK:
            return "WM2_UNLOCK"
        case .WEB_LOCK:
            return "WEB_LOCK"
        case .WEB_UNLOCK:
            return "WEB_UNLOCK"
        case .BLE_CLICK:
            return "BLE_CLICK"
        case .WM2_CLICK:
            return "WM2_CLICK"
        case .WEB_CLICK:
            return "WEB_CLICK"
        case .DRIVE_CLICK:
            return "DRIVE_CLICK"
        case .MANUAL_CLICK:
            return "MANUAL_CLICK"
        }
    }
}
