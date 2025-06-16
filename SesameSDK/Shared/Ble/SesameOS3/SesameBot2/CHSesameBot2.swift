//
//  CHsesameBot2.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/13.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

/// 動作類型，正傳、反轉、停止（無慣性）、睡眠（有慣性）
public enum BotActionType: UInt8 {
    case forward = 0
    case reverse = 1
    case stop = 2
    case sleep = 3
}

/// 腳本動作，最多可以有20個
public struct Bot2Action {
    public var action: BotActionType
    public var time: UInt8
    public init(action: BotActionType, time: UInt8) {
        self.action = action
        self.time = time
    }
}

// 結構體轉 data
extension Bot2Action {
    mutating func todata() -> Data {
        return Data(bytes: &self, count: MemoryLayout<Bot2Action>.size)
    }
}

/// 腳本結構
public struct CHSesamebot2Event{
    public let nameLength: UInt8
    public let name: [UInt8]
    public var actionLength: UInt8?
    public var actions: [Bot2Action]?
}

// 從data恢復結構體
public extension CHSesamebot2Event {
    static func fromData(_ buf: Data) -> CHSesamebot2Event? {
        let startIdx = 0
        var cursor = startIdx
        let nameLength = buf[cursor]
        if nameLength < 1 { return nil }
        cursor += 1
        let name = buf[safeBound: cursor ... (cursor + Int(nameLength)) - 1]!.bytes
        cursor += 20
        var event = CHSesamebot2Event(nameLength: nameLength, name: name)
        let actionLength = buf[cursor]
        guard actionLength > 0 else { return event }
        var actions = [Bot2Action]()
        while cursor < buf.count - 1 {
            cursor += 1
            let action = BotActionType(rawValue: buf[cursor])
            cursor += 1
            let time = buf[cursor]
            actions.append(Bot2Action(action: action!, time: time))
        }
        event.actionLength = actionLength
        event.actions = actions
        return event
    }
    
    mutating func toData() -> Data {
        var cursor: Data = Data()
        cursor += nameLength.data
        let nameData = Data(name) + Data(repeating: 0, count: 20 - Int(nameLength))
        cursor += nameData
        cursor += actionLength!.data
        var idx = 0
        while idx < Int(actionLength!) {
            var action = actions![idx]
            cursor += Data(bytes: &action, count: MemoryLayout<Bot2Action>.size)
            idx += 1
        }
        return cursor
    }
}

/// 腳本列表結構（action 只包含 name、nameLength）
public struct CHSesamebot2Status {
    public var curIdx: UInt8
    public let eventLength: UInt8
    public let events: [CHSesamebot2Event]
}

public extension CHSesamebot2Status {
    static func fromData(_ buf: Data) -> CHSesamebot2Status? {
        var cursor = 0
        let curIdx = buf[cursor]
        cursor += 1
        let eventLength = buf[cursor]
        if curIdx >= eventLength { return nil }
        cursor += 1
        var events = [CHSesamebot2Event]()
        for _ in 0 ..< eventLength {
            // [eddy todo] 可能某个剧本的 nameLength 为0，这会导致下面的crash，打补丁至少1。【固件未按协议给数据】
            let nameLength = max(buf[cursor], 1)
            cursor += 1
            let name = buf[safeBound: cursor ... (cursor + Int(nameLength)) - 1]!.bytes
            events.append(CHSesamebot2Event(nameLength: nameLength, name: name))
            cursor += 20
        }
        return CHSesamebot2Status(curIdx: curIdx, eventLength: eventLength, events: events)
    }
}

public protocol CHSesameBot2: CHSesameLock {
    
    var scripts: CHSesamebot2Status { get }
    /// 發送指令
    /// - Parameters:
    ///   - index: 當前腳本下標，不傳默認執行當前設置的下標
    ///   - result: 結果狀態
    func click(index: UInt8?, result: @escaping (CHResult<CHEmpty>))

    /// 發送腳本數據
    /// - Parameters:
    ///   - script: CHSesamebot2Event data
    ///   - result: 結果狀態
    func sendClickScript(index: UInt8, script: Data, result: @escaping (CHResult<CHEmpty>))
    
    /// 選擇腳本
    /// - Parameters:
    ///   - index: 腳本下標
    ///   - result: 結果狀態
    func selectScript(index: UInt8, result: @escaping (CHResult<CHEmpty>))
    
    /// 獲取指定腳本
    /// - Parameter result: 返回 CHSesamebot2Event data
    func getCurrentScript(index: UInt8?, result: @escaping (CHResult<CHSesamebot2Event>))

    /// 獲取所有腳本
    /// - Parameter result: 返回 CHSesamebot2Status data
    func getScriptNameList(result: @escaping (CHResult<CHSesamebot2Status>))
}

