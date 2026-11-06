//
//  CHRemoteNanoTriggerSettings.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
public struct CHRemoteBaseTriggerSettings {
    public var triggerDelaySecond: UInt8
    static func fromData(_ buf: Data) -> CHRemoteBaseTriggerSettings? {
        return buf.loadStruct(self)
    }
}
