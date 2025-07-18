//
//  SwitchProtocols.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation


public enum CHSesameBotUserPreDir: UInt8 {
    case normal = 0
    case reversed = 1
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBotUserPreDir>.size)
    }
}

public enum CHSesameBotButtonMode: UInt8 {
    case click = 0
    case toggle = 1
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBotButtonMode>.size)
    }
}

public struct CHSesameBotLockSecondsConfiguration {
    public var lockSeconds: UInt8
    public var unlockSeconds: UInt8
    public var clickLockSeconds: UInt8
    public var clickHoldSeconds: UInt8
    public var clickUnlockSeconds: UInt8

    init(lockSeconds: UInt8,
         unlockSeconds: UInt8,
         clickLockSeconds: UInt8,
         clickHoldSeconds: UInt8,
         clickUnlockSeconds: UInt8) {
        self.lockSeconds = lockSeconds
        self.unlockSeconds = unlockSeconds
        self.clickLockSeconds = clickLockSeconds
        self.clickHoldSeconds = clickHoldSeconds
        self.clickUnlockSeconds = clickUnlockSeconds
    }
    
    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesameBotLockSecondsConfiguration>.size)
    }
}
