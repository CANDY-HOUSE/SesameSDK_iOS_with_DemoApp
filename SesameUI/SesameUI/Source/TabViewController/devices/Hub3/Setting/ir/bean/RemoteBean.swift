//
//  IRRemote.swift
//  SesameUI
//
//  Created by wuying on 2025/9/8.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public class IRRemote: Codable {
    public let uuid: String
    public private(set) var alias: String
    public var model: String
    public var type: Int
    public let timestamp: Int
    public private(set) var state: String?
    public var code: Int = 0
    public var haveSave: Bool = true
    public var direction: String = "" // 新添加的字段，默认值为空字符串
    
    public func updateState(_ newState: String?) {
        self.state = newState
    }
    
    public func updateAlias(_ newAlias: String) {
        self.alias = newAlias
    }
    
    public init(uuid: String, alias: String, model: String, type: Int, timestamp: Int, state: String? = nil, code: Int = 0, direction: String = "") {
        self.uuid = uuid
        self.alias = alias
        self.model = model
        self.type = type
        self.timestamp = timestamp
        self.state = state
        self.code = code
        self.haveSave = true
        self.direction = direction
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case alias
        case model
        case type
        case timestamp
        case state
        case code
        case direction
    }
    
    public func clone() -> IRRemote {
        let cloned = IRRemote(
            uuid: self.uuid,
            alias: self.alias,
            model: self.model,
            type: self.type,
            timestamp: self.timestamp,
            state: self.state,
            direction: self.direction
        )
        cloned.code = self.code
        cloned.haveSave = self.haveSave
        return cloned
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? UUID().uuidString
        alias = try container.decode(String.self, forKey: .alias)
        model = try container.decode(String.self, forKey: .model)
        type = try container.decodeIfPresent(Int.self, forKey: .type) ?? 0
        timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp) ?? Int(Date().timeIntervalSince1970)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        code = try container.decodeIfPresent(Int.self, forKey: .code) ?? 0
        direction = try container.decodeIfPresent(String.self, forKey: .direction) ?? ""
        haveSave = true
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(alias, forKey: .alias)
        try container.encode(model, forKey: .model)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encode(code, forKey: .code)
        try container.encode(direction, forKey: .direction)
    }
}

extension IRRemote {
    public func swapRemote(_ irType: Int) -> IRRemote {
       return IRRemote(
            uuid: UUID().uuidString.uppercased(),
            alias: self.alias,
            model: self.model,
            type: irType,
            timestamp: 0,
            state: self.state,
            code: self.code,
            direction: self.direction
        )
    }
}

/// 新增红外设备
public typealias IRDeviceCode = Int
public struct IRDevicePayload: Codable {
    public let uuid: String
    public let model: String
    public var alias: String
    public let deviceUUID: String
    public let state: String
    public let type: IRDeviceCode
    public var keys: [IRCode]
    public var code: Int
    
    public init(uuid: String, model: String, alias: String, deviceUUID: String, state: String, type: IRDeviceCode, keys: [IRCode], code:Int) {
        self.uuid = uuid
        self.model = model
        self.alias = alias
        self.deviceUUID = deviceUUID
        self.state = state
        self.type = type
        self.keys = keys
        self.code = code
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, model, alias, deviceUUID, keys, type, state, code
    }
}

public class MatchIRRemote: Codable {
    public  var matchPercent: String;
    public  var remote: IRRemote;
    
    public init(matchPercent: String, remote: IRRemote) {
        self.matchPercent = matchPercent
        self.remote = remote
    }
    
    enum CodingKeys: String, CodingKey {
        case matchPercent
        case remote
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchPercent = try container.decode(String.self, forKey: .matchPercent)
        remote = try container.decode(IRRemote.self, forKey: .remote)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matchPercent, forKey: .matchPercent)
        try container.encode(remote, forKey: .remote)
    }
}

public struct IRCode: Codable, Equatable {
    public var keyUUID: String
    public var name: String?
    
    public init(keyUUID: String, name: String?) {
        self.keyUUID = keyUUID
        self.name = name
    }
    
    enum CodingKeys: CodingKey {
        case keyUUID
        case name
    }
    
    static func fromData(_ buf: Data) -> IRCode {
        let codeId = String(format: "%02X", buf[0])
        return IRCode(keyUUID: codeId, name: nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyUUID, forKey: .keyUUID)
        if (name != nil) {
            try container.encode(name, forKey: .name)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyUUID = try container.decode(String.self, forKey: .keyUUID)
        name = try container.decode(String.self, forKey: .name)
    }
}

