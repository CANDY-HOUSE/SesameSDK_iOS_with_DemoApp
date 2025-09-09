//
//  IRRemote.swift
//  SesameUI
//
//  Created by wuying on 2025/9/8.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

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

