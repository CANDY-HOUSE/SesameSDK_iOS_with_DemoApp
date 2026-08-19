//
//  LoginViewController.swift
//  SesameUI
//
//  Biz H5 登录页：H5 负责界面，native 通过 bridge 走 SDK 登录（CUSTOM_AUTH）。
//

import UIKit
import SesameSDK

class LoginViewController: CHWebHostViewController {

    private var loginURL: String = ""

    override var webDirectURL: String? { loginURL }
    override var showsNavigationRightMenu: Bool { false }
    override var enablesPullToRefresh: Bool { false }

    static func instance(urlString: String) -> LoginViewController {
        let vc = LoginViewController(nibName: nil, bundle: nil)
        vc.loginURL = urlString
        vc.hidesBottomBarWhenPushed = true
        return vc
    }

    override func registerExtraHandlers(on web: CHWebView) {
        // 发送验证码：H5 传 email，native 触发 Cognito 发码
        web.registerMessageHandler(WebViewMessageType.requestSignIn.rawValue) { webView, data in
            guard let params = data as? [String: Any],
                  let email = params["email"] as? String,
                  let callbackName = params["callbackName"] as? String else { return }
            CHAWSManager.signIn(username: email, password: "dummypwk") { state, error in
                if let error = error {
                    webView.callH5(funcName: callbackName, data: ["success": false, "error": error.localizedDescription])
                    return
                }
                // .customChallenge 表示已发码，等待用户输入验证码
                let needCode: Bool
                if case .customChallenge? = state { needCode = true } else { needCode = false }
                webView.callH5(funcName: callbackName, data: ["success": true, "needCode": needCode])
            }
        }
        // 提交验证码：H5 传 code，native 完成登录
        web.registerMessageHandler(WebViewMessageType.requestConfirmSignIn.rawValue) { [weak self] webView, data in
            guard let params = data as? [String: Any],
                  let code = params["code"] as? String,
                  let callbackName = params["callbackName"] as? String else { return }
            CHAWSManager.confirmSignIn(challengeResponse: code) { state, error in
                if let error = error {
                    webView.callH5(funcName: callbackName, data: ["success": false, "error": error.localizedDescription])
                    return
                }
                var signedIn = false
                if case .signedIn? = state { signedIn = true }
                webView.callH5(funcName: callbackName, data: ["success": true, "signedIn": signedIn])
                if signedIn {
                    executeOnMainThread { [weak self] in
                        self?.onLoginSucceeded()
                    }
                }
            }
        }
        // 外部浏览器打开 URL
        web.registerMessageHandler(WebViewMessageType.requestOpenExternalURL.rawValue) { _, data in
            guard let urlString = (data as? [String: Any])?["url"] as? String,
                  let url = URL(string: urlString) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    /// 登录成功：关闭登录页 + 初始化昵称（若无）；「我的」页刷新由其登录态监听兜底
    private func onLoginSucceeded() {
        navigationController?.popViewController(animated: true)
        CHAWSMobileClient.shared.getName { result in
            if case let .success(nickname) = result, nickname == nil {
                CHAWSMobileClient.shared.getEmail { getEmailResult in
                    if case let .success(email) = getEmailResult,
                       let email = email,
                       let emailId = email.split(separator: "@").first.map(String.init) {
                        CHAWSMobileClient.shared.updateName(emailId) { _ in }
                    }
                }
            }
            if let token = UserDefaults.standard.value(forKey: "devicePushToken") as? String {
                PushNotificationManager.shared.handleAPNsToken(token)
            }
        }
    }
}
