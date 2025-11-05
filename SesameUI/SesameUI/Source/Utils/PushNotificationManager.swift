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
    
    var appIdentifyId: String {
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
        L.d("sf", "appIdentifyId=\(appIdentifyId)")
        
        guard let token = UserDefaults.standard.string(forKey: "devicePushToken") else {
            L.d("sf", "无token，需要注册推送...")
            registerForPushNotifications()
            return
        }
        
        if shouldRefreshSubscriptions() {
            L.d("sf", "需要更新订阅...")
            forceRefreshSubscriptions(token: token)
        } else {
            L.d("sf", "检查现有订阅...")
            subscribeToTopicsIfNeeded(token: token)
        }
    }
    
    private func shouldRefreshSubscriptions() -> Bool {
        let lastSubscriptionTime = prefs.double(forKey: "last_subscription_time")
        let lastAppVersion = prefs.string(forKey: PREF_APP_VERSION) ?? "0"
        let currentTime = Date().timeIntervalSince1970
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        L.d("sf", "currentAppVersion=\(currentAppVersion)")
        
        return currentAppVersion != lastAppVersion ||
        (currentTime - lastSubscriptionTime) > SUBSCRIPTION_REFRESH_INTERVAL
    }
    
    private func forceRefreshSubscriptions(token: String) {
        clearAllTokenSubscriptions()
        subscribeToTopicsIfNeeded(token: token)
    }
    
    private func clearAllTokenSubscriptions() {
        prefs.dictionaryRepresentation()
            .keys
            .filter { $0.hasPrefix("topic_") }
            .forEach { prefs.removeObject(forKey: $0) }
        
        L.d("sf", "已清除所有订阅记录，将强制重新订阅")
    }
    
    private func subscribeToTopicsIfNeeded(token: String) {
        // 防止重复订阅
        if subscribingTokens.contains(token) {
            L.d("sf", "正在订阅中，跳过。Token:\(token.suffix(10))")
            return
        }
        
        subscribingTokens.insert(token)
        
        topics.forEach { topic in
            if !isTopicSubscribed(topic: topic, token: token){
                subscribeToTopic(topic: topic, token: token)
            } else {
                L.d("sf", "Topic:\(topic) Token:\(token.suffix(10)) 已经订阅过了")
            }
        }
    }
    
    private func isTopicSubscribed(topic: String, token: String) -> Bool {
        let tokenSuffix = String(token.suffix(10))
        let key = "topic_\(topic)_\(tokenSuffix)"
        return prefs.bool(forKey: key)
    }
    
    private func subscribeToTopic(topic: String, token: String) {
        CHAccountManager.shared.subscribeToSNSTopic(
            topicName: topic,
            pushToken: token,
            appIdentifyId: appIdentifyId,
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
            
            checkIfAllTopicsSubscribed(token: token)
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
    
    func handleAPNsToken(_ token: String) {
        L.d("sf", "handleAPNsToken=\(token)")
        
        let oldToken = UserDefaults.standard.string(forKey: "devicePushToken")
        
        if oldToken != token {
            L.d("sf", "Token已变更，强制刷新订阅")
            UserDefaults.standard.setValue(token, forKey: "devicePushToken")
            forceRefreshSubscriptions(token: token)
        } else {
            L.d("sf", "Token未变更，跳过处理")
        }
    }
    
    private func checkIfAllTopicsSubscribed(token: String) {
        let allSubscribed = topics.allSatisfy { isTopicSubscribed(topic: $0, token: token) }
        if allSubscribed {
            subscribingTokens.remove(token)
            L.d("sf", ">>>> Token:\(token.suffix(10)) 的所有主题订阅完成")
        }
    }
}
