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

extension IRRemote: CellSubItemDiscriptor {
    
    var title: String {
        return self.alias
    }
    
    func iconWithDevice(_ device: CHDevice) -> String? {
        return nil
    }
    
    func convertToCellDescriptorModel(device: CHDevice, cellCls: AnyClass) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            guard let emitCell = cell as? Hub3IREmitCell else {
                return
            }
            emitCell.device = device
            emitCell.configure(item: self)
        }
    }
}

