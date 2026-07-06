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

    private let topic = "app_announcements"

    var platform: String {
#if DEBUG
        return "ios_sandbox"
#else
        return "ios"
#endif
    }

    /// 注册失败（如首次安装且无网，走 didFailToRegister）时调用：
    /// 挂一次性网络监听，恢复后补注册一次 → didRegister → handleAPNsToken。
    func registerWhenNetworkAvailable() {
        NetworkReachabilityHelper.shared.addListener(self) { [weak self] state in
            guard case .reachable = state, let self = self else { return }
            NetworkReachabilityHelper.shared.removeListener(self)
            DispatchQueue.main.async {
                L.d("sf", "网络恢复，补注册以重取 token")
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// 拿到 / 更新 APNs token：保存并订阅（授权弹窗与注册由 AppDelegate 负责）。
    func handleAPNsToken(_ token: String) {
        L.d("sf", "handleAPNsToken=\(token)")
        UserDefaults.standard.setValue(token, forKey: "devicePushToken")
        subscribeToTopic(token: token)
    }

    // MARK: - 订阅（每次调用直接订阅，SNS 幂等，无节流 / 去重 / 状态记录）

    private func subscribeToTopic(token: String) {
        // 无网：挂一次性监听，恢复后重试自己（重试由真失败驱动，避免启动时误触发双调）
        guard NetworkReachabilityHelper.shared.isReachable else {
            NetworkReachabilityHelper.shared.addListener(self) { [weak self] state in
                guard case .reachable = state, let self = self else { return }
                NetworkReachabilityHelper.shared.removeListener(self)
                self.subscribeToTopic(token: token)
            }
            return
        }
        AppEnvironment.collect { [weak self] env in
            guard let self = self else { return }
            let topic = self.topic
            CHAPIClient.shared.subscribeToSNSTopic(
                topicName: topic,
                pushToken: token,
                platform: self.platform,
                env: env
            ) { success, envId in
                if success, let hisTag = envId {
                    let ss5history = CHAWSMobileClient.shared.formatSubuuid(hisTag)
                    Sesame2Store.shared.setEnvironmentId(ss5history)
                    CHDeviceManager.shared.setHistoryTag()
                }
                L.d("sf", success ? "订阅成功: \(topic) envId=\(envId ?? "")" : "订阅失败: \(topic)")
            }
        }
    }
}
