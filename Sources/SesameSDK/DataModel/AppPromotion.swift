//
//  AppPromotion.swift
//  SesameSDK
//
//  Created by Codex on 2026/7/7.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

public struct AppPromotion: Codable {
    public let promotionId: String
    public let enabled: Bool
    public let visible: Bool
    public let targetUrl: String

    public init(
        promotionId: String,
        enabled: Bool,
        visible: Bool,
        targetUrl: String
    ) {
        self.promotionId = promotionId
        self.enabled = enabled
        self.visible = visible
        self.targetUrl = targetUrl
    }
}

struct AppPromotionResponse: Codable {
    let promotion: AppPromotion
}

struct AppPromotionReadRequest: Codable {
    let action: String
    let promotionId: String
    let platform: String
    let targetUrl: String?

    init(promotionId: String, targetUrl: String?) {
        self.action = "markPromotionRead"
        self.promotionId = promotionId
        self.platform = "ios"
        self.targetUrl = targetUrl
    }
}
