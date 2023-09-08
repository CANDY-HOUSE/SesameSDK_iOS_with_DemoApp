//
//  CHSesameBike2.swift
//  SesameSDK
//
//  Created by JOi Chao on 2023/5/30.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation

public protocol CHSesameBike2: CHSesameLock {
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
}

extension CHSesameBike2 {
    public func unlock(result: @escaping (CHResult<CHEmpty>)) {
        unlock(historytag: nil, result: result)
    }
}


struct CHSesameBike2MechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let flags: UInt8 
    var data: Data {battery.data + flags.data}
    var isInLockRange: Bool { return flags & 2 > 0 }
    var isStop: Bool? { return flags & 4 > 0 }

    func getBatteryVoltage() -> Float {
        return Float(battery) * 2.0 / 1000.0
    }

    static func fromData(_ buf: Data) -> CHSesameBike2MechStatus? {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
