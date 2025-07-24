//
//  PushNotificationManager.swift
//  SesameUI
//
//  Created by frey Mac on 2025/7/21.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import UIKit
import UserNotifications
import SesameSDK

class PushNotificationManager {
    static let shared = PushNotificationManager()
    
    private let prefs = UserDefaults.standard
    private let topics = ["app_announcements"]
    
    private let PREF_APP_VERSION = "last_subscription_app_version"
    private let SUBSCRIPTION_REFRESH_INTERVAL: TimeInterval = 30 * 24 * 60 * 60
    
    var appDeviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    var platform: String {
#if DEBUG
        return "ios_sandbox"
#else
        return "ios"
#endif
    }
    
    private var subscribingTokens = Set<String>()
    
    func checkAndSubscribeToTopics() {
        L.d("sf", "appDeviceId=\(appDeviceId)")
        
        if shouldRefreshSubscriptions() {
            L.d("sf", "需要更新订阅...")
            
            // 如果已有 token，直接强制刷新
            if let token = prefs.string(forKey: "apns_token") {
                forceRefreshSubscriptions(token: token)
            } else {
                // 没有 token，需要重新注册
                registerForPushNotifications()
            }
        } else {
            L.d("sf", "检查现有订阅...")
            if let token = prefs.string(forKey: "apns_token") {
                subscribeToTopicsIfNeeded(token: token)
            }
        }
    }
    
    private func shouldRefreshSubscriptions() -> Bool {
        let storedToken = prefs.string(forKey: "apns_token")
        let lastSubscriptionTime = prefs.double(forKey: "last_subscription_time")
        let lastAppVersion = prefs.string(forKey: PREF_APP_VERSION) ?? "0"
        let currentTime = Date().timeIntervalSince1970
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        L.d("sf", "currentAppVersion=\(currentAppVersion)")
        
        return storedToken == nil ||
        currentAppVersion != lastAppVersion ||
        (currentTime - lastSubscriptionTime) > SUBSCRIPTION_REFRESH_INTERVAL
    }
    
    private func subscribeToTopicsIfNeeded(token: String) {
        // 防止重复订阅
        if subscribingTokens.contains(token) {
            L.d("sf", "正在订阅中，跳过。Token:\(token.suffix(10))")
            return
        }
        
        subscribingTokens.insert(token)
        prefs.set(token, forKey: "apns_token")
        
        topics.forEach { topic in
            if !isTopicSubscribed(topic: topic, token: token){
                subscribeToTopic(topic: topic, token: token)
            } else {
                L.d("sf", "Topic:\(topic) Token:\(token.suffix(10)) 已经订阅过了")
            }
        }
        
        // 检查是否所有主题都已订阅
        checkIfAllTopicsSubscribed(token: token)
    }
    
    private func isTopicSubscribed(topic: String, token: String) -> Bool {
        let tokenSuffix = String(token.suffix(10))
        let key = "topic_\(topic)_\(tokenSuffix)"
        return prefs.bool(forKey: key)
    }
    
    private func subscribeToTopic(topic: String, token: String) {
        CHAccountManager.shared.subscribeToSNSTopic(
            topicName: topic,
            token: token,
            deviceId: appDeviceId,
            platform: platform
        ) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                let tokenSuffix = String(token.suffix(10))
                let key = "topic_\(topic)_\(tokenSuffix)"
                self.prefs.set(true, forKey: key)
                self.prefs.set(Date().timeIntervalSince1970, forKey: "last_subscription_time")
                self.prefs.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
                               forKey: self.PREF_APP_VERSION)
                L.d("sf", "订阅成功: \(topic)")
            } else {
                L.d("sf", "订阅失败: \(topic)")
            }
        }
    }
    
    func registerForPushNotifications() {
        L.d("sf", "注册通知……")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func handleAPNsToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        L.d("sf", "handleAPNsToken=\(token)")
        
        if let oldToken = prefs.string(forKey: "apns_token"), oldToken != token {
            L.d("sf", "只清除旧 token 的订阅记录")
            let oldTokenSuffix = String(oldToken.suffix(10))
            topics.forEach { topic in
                let key = "topic_\(topic)_\(oldTokenSuffix)"
                prefs.removeObject(forKey: key)
            }
        }
        
        subscribeToTopicsIfNeeded(token: token)
    }
    
    private func forceRefreshSubscriptions(token: String) {
        let tokenSuffix = String(token.suffix(10))
        topics.forEach { topic in
            let key = "topic_\(topic)_\(tokenSuffix)"
            prefs.removeObject(forKey: key)
        }
        L.d("sf", "已清除token的订阅记录，将强制重新订阅")
        subscribeToTopicsIfNeeded(token: token)
    }
    
    private func checkIfAllTopicsSubscribed(token: String) {
        let allSubscribed = topics.allSatisfy { isTopicSubscribed(topic: $0, token: token) }
        if allSubscribed {
            subscribingTokens.remove(token)
            L.d("sf", ">>>> Token:\(token.suffix(10)) 的所有主题订阅完成")
        }
    }
}
