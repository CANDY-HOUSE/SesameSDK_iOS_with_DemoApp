//
//  CHSesameTouchProMechStatus.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/7.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
struct CHSesameTouchProMechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let target: Int16
    let position: Int16
    let flags: UInt8
    var data: Data {battery.data + target.data + position.data  + flags.data}
    var isClutchFailed: Bool { return false}
    var isInLockRange: Bool { return false }
    var isInUnlockRange: Bool { return false}
    var isStop: Bool? { return false }
    var isBatteryCritical: Bool { return false}

    static func fromData(_ buf: Data) -> CHSesameTouchProMechStatus? {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
