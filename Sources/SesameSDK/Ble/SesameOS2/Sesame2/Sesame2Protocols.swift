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
