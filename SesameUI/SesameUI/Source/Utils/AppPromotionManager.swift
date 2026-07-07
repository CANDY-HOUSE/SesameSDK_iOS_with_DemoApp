//
//  AppPromotionManager.swift
//  SesameUI
//
//  Created by frey Mac on 2026/7/7.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

final class AppPromotionManager {
    static let shared = AppPromotionManager()
    static let promotionChangedNotification = Notification.Name("AppPromotionChanged")
    
    private(set) var currentPromotion: AppPromotion?
    
    private init() {}
    
    func refresh(_ completion: ((AppPromotion?) -> Void)? = nil) {
        CHAPIClient.shared.getActivePromotion { [weak self] result in
            switch result {
            case .success(let response):
                executeOnMainThread {
                    self?.currentPromotion = response.data
                    self?.notifyChanged()
                    completion?(response.data)
                }
            case .failure(let error):
                L.d("AppPromotionManager refresh failed", error)
                executeOnMainThread {
                    completion?(self?.currentPromotion)
                }
            }
        }
    }
    
    func markRead(
        promotionId: String,
        targetUrl: String?,
        completion: ((AppPromotion?) -> Void)? = nil
    ) {
        guard Thread.isMainThread else {
            executeOnMainThread { [weak self] in
                self?.markRead(
                    promotionId: promotionId,
                    targetUrl: targetUrl,
                    completion: completion
                )
            }
            return
        }

        let basePromotion: AppPromotion
        if let currentPromotion = currentPromotion,
           currentPromotion.promotionId == promotionId {
            basePromotion = currentPromotion
        } else {
            basePromotion = AppPromotion(
                promotionId: promotionId,
                enabled: true,
                visible: true,
                targetUrl: targetUrl ?? ""
            )
        }
        let hiddenPromotion = AppPromotion(
            promotionId: promotionId,
            enabled: basePromotion.enabled,
            visible: false,
            targetUrl: targetUrl ?? basePromotion.targetUrl
        )
        executeOnMainThread { [weak self] in
            self?.currentPromotion = hiddenPromotion
            self?.notifyChanged()
        }
        
        CHAPIClient.shared.markPromotionRead(promotionId: promotionId, targetUrl: targetUrl) { [weak self] result in
            switch result {
            case .success(let response):
                executeOnMainThread {
                    self?.currentPromotion = response.data
                    self?.notifyChanged()
                    completion?(response.data)
                }
            case .failure(let error):
                L.d("AppPromotionManager markRead failed", error)
                executeOnMainThread {
                    completion?(hiddenPromotion)
                }
            }
        }
    }
    
    private func notifyChanged() {
        NotificationCenter.default.post(
            name: AppPromotionManager.promotionChangedNotification,
            object: currentPromotion
        )
    }
}
