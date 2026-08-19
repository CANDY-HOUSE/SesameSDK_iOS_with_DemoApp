//
//  MeViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import UserNotifications

extension MeViewController {
    static func instance() -> MeViewController {
        let meViewController = MeViewController(nibName: nil, bundle: nil)
        let _ = UINavigationController(rootViewController: meViewController)
        return meViewController
    }
}

class MeViewController: CHWebHostViewController {

    override var webScene: String? { "me-homepage" }
    lazy var appVersionInfo: [String: Any] = {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        var revision = ""
        if let path = Bundle.main.path(forResource: "git", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            revision = dict["GitCommit"] as? String ?? ""
        }
        return [
            "display": "\(appVersion)(\(bundleVersion)) - \(revision)"
        ]
    }()
    
    override func didFinishInitialSetup() {
        CHAWSManager.addUserStateListener(self) { [weak self] _ in
            executeOnMainThread { self?.webView?.refresh() }
        }
    }

    override func registerExtraHandlers(on web: CHWebView) {
        web.registerMessageHandler(WebViewMessageType.requestLogin.rawValue) { [weak self] _, data in
            guard let urlString = (data as? [String: Any])?["url"] as? String else { return }
            self?.presentBizLoginWebView(urlString: urlString)
        }
        // 登出（确认交互由 H5 actionSheet 处理，native 只执行登出）
        web.registerMessageHandler(WebViewMessageType.requestSignOut.rawValue) { [weak self] webView, data in
            let callbackName = (data as? [String: Any])?["callbackName"] as? String
            self?.signOut {
                if let cb = callbackName {
                    webView.callH5(funcName: cb, data: ["success": true])
                }
            }
        }
        // 登录态查询
        web.registerMessageHandler(WebViewMessageType.requestAuthState.rawValue) { webView, data in
            guard let cb = (data as? [String: Any])?["callbackName"] as? String else { return }
            webView.callH5(funcName: cb, data: [
                "signedIn": CHAWSManager.isSignedIn,
                "state": CHAWSManager.currentUserState.rawValue
            ])
        }
        // 版本号
        web.registerMessageHandler(WebViewMessageType.requestAppVersion.rawValue) { [weak self] webView, data in
            guard let self = self, let cb = (data as? [String: Any])?["callbackName"] as? String else { return }
            webView.callH5(funcName: cb, data: self.appVersionInfo)
        }
        // 外部浏览器打开 URL
        web.registerMessageHandler(WebViewMessageType.requestOpenExternalURL.rawValue) { _, data in
            guard let urlString = (data as? [String: Any])?["url"] as? String,
                  let url = URL(string: urlString) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        // 推送 token（供 H5 检查匿名 token 是否上云）
        web.registerMessageHandler(WebViewMessageType.requestPushToken.rawValue) { webView, data in
            guard let cb = (data as? [String: Any])?["callbackName"] as? String else { return }
            let token = UserDefaults.standard.string(forKey: "devicePushToken") ?? ""
            webView.callH5(funcName: cb, data: ["pushToken": token])
        }
        // 通知授权状态
        web.registerMessageHandler(WebViewMessageType.requestNotificationStatus.rawValue) { webView, data in
            guard let cb = (data as? [String: Any])?["callbackName"] as? String else { return }
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let isEnabled = settings.authorizationStatus == .authorized
                webView.callH5(funcName: cb, data: ["enabled": isEnabled])
            }
        }
        // 获取红点状态
        web.registerMessageHandler(WebViewMessageType.requestActivePromotion.rawValue) { webView, data in
            guard let params = data as? [String: Any], let callbackName = params["callbackName"] as? String else { return }
            AppPromotionManager.shared.refresh { promotion in
                webView.callH5(
                    funcName: callbackName,
                    data: promotion.responseData
                )
            }
        }
        // 标记红点为已读
        web.registerMessageHandler(WebViewMessageType.requestMarkPromotionRead.rawValue) { webView, data in
            guard let params = data as? [String: Any], let callbackName = params["callbackName"] as? String else { return }
            guard let promotionId = params["promotionId"] as? String,
                  promotionId.isEmpty == false else {
                webView.callH5(funcName: callbackName, data: ["success": false])
                return
            }
            let targetUrl = params["targetUrl"] as? String
            AppPromotionManager.shared.markRead(promotionId: promotionId, targetUrl: targetUrl) { promotion in
                webView.callH5(
                    funcName: callbackName,
                    data: promotion.responseData
                )
            }
        }
    }

    // MARK: - 登录
    private func presentBizLoginWebView(urlString: String) {
        let loginVC = LoginViewController.instance(urlString: urlString)
        navigationController?.pushViewController(loginVC, animated: true)
    }

    // MARK: - 登出
    private func signOut(completion: @escaping () -> Void) {
        CHAWSMobileClient.shared.signOut {
            CHDeviceWrapperManager.shared.clear()
            if let token = UserDefaults.standard.value(forKey: "devicePushToken") as? String {
                PushNotificationManager.shared.handleAPNsToken(token)
            }
            executeOnMainThread { completion() }
        }
    }
}


private extension Optional where Wrapped == AppPromotion {
    var responseData: [String: Any] {
        guard let promotion = self else {
            return ["success": false]
        }
        return [
            "success": true,
            "promotionId": promotion.promotionId,
            "enabled": promotion.enabled,
            "visible": promotion.visible,
            "targetUrl": promotion.targetUrl
        ]
    }
}
