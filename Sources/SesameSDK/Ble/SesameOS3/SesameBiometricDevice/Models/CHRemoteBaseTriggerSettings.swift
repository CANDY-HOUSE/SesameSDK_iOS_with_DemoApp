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
        let content = buf.copyData
        return content.withUnsafeBytes({ $0.load(as: self) })
    }
}
