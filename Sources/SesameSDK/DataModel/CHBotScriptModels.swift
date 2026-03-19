//
//  CHBotScriptModels.swift
//  SesameWatchKitSDK
//
//  Created by frey Mac on 2026/3/18.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

public struct BotScriptItem: Codable {
    public let actionIndex: String
    public let alias: String?
    public let displayOrder: Int?
    public let isDefault: Int?

    public init(actionIndex: String,
                alias: String? = nil,
                displayOrder: Int? = nil,
                isDefault: Int? = nil) {
        self.actionIndex = actionIndex
        self.alias = alias
        self.displayOrder = displayOrder
        self.isDefault = isDefault
    }
}

public struct BotScriptRequest: Codable {
    public let deviceUUID: String
    public let actionIndex: String?
    public let alias: String?
    public let isDefault: Int?
    public let actionData: String?
    public let displayOrder: Int?
    public let deleteAll: Bool?
    public let batchDisplayOrders: [BotScriptItem]?

    public init(deviceUUID: String,
                actionIndex: String? = nil,
                alias: String? = nil,
                isDefault: Int? = nil,
                actionData: String? = nil,
                displayOrder: Int? = nil,
                deleteAll: Bool? = nil,
                batchDisplayOrders: [BotScriptItem]? = nil) {
        self.deviceUUID = deviceUUID
        self.actionIndex = actionIndex
        self.alias = alias
        self.isDefault = isDefault
        self.actionData = actionData
        self.displayOrder = displayOrder
        self.deleteAll = deleteAll
        self.batchDisplayOrders = batchDisplayOrders
    }
}
