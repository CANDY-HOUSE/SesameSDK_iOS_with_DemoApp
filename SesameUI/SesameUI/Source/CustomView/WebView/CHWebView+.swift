//
//  CHWebViewController+.swift
//  SesameUI
//
//  Created by eddy on 2025/9/30.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SesameSDK
import Foundation
import UIKit

enum WebViewMessageType: String {
    case requestRefreshApp = "requestRefreshApp"
    case requestEnablePullRefresh = "requestEnablePullRefresh"
    case requestDestroySelf = "requestDestroySelf"
    case requestAutoLayoutHeight = "requestAutoLayoutHeight"
    case requestLogin = "requestLogin"
    case requestPushToken = "requestPushToken"// 检查匿名 token 是否上云
    case requestNotificationStatus = "requestNotificationStatus"
    case requestNotificationSettings = "requestNotificationSettings"
    case requestActivePromotion = "requestActivePromotion"
    case requestMarkPromotionRead = "requestMarkPromotionRead"
    case requestBLEConnect = "requestBLEConnect"
    case requestConfigureInternet = "requestConfigureInternet"
    case requestMonitorInternet = "requestMonitorInternet"
    case requestDeviceFWUpgrade = "requestDeviceFWUpgrade"
    case requestUpdateDeviceFWVersion = "requestUpdateDeviceFWVersion"
}

enum WebViewSchemeType: String {
    case notify = "ssm://UI/webview/notify"
    case registNotify = "ssm://UI/webview/registNotify"
}

extension CHWebView {
    func registerMessageHandlers() {
        
        registerMessageHandler(WebViewMessageType.requestEnablePullRefresh.rawValue) { webView, data in
            webView.enablePullToRefresh {
                webView.refresh()
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestDestroySelf.rawValue) { [self] webView, data in
            guard let vc = currentViewController else { return }
            if vc.presentingViewController != nil {
                vc.dismiss(animated: true)
            } else if let navController = vc.navigationController,
                      navController.viewControllers.count > 0 {
                navController.popViewController(animated: true)
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestRefreshApp.rawValue) { [self] webView, data in
            refreshDeviceList()
        }
        
        registerMessageHandler(WebViewMessageType.requestNotificationSettings.rawValue) { webView, data in
            if let _ = data as? [String: Any] {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestUpdateDeviceFWVersion.rawValue) { webView, data in
            guard let params = data as? [String: Any] else {
                return
            }
            
            guard let deviceId = params["deviceUUID"] as? String,
                  let currentFwVer = params["currentFwVer"] as? String else {
                return
            }
            
            L.d("[requestUpdateDeviceFWVersion]", deviceId, currentFwVer)
            
            CHDeviceWrapperManager.shared.updateCurrentFwVer(
                for: deviceId,
                currentFwVer: currentFwVer
            ) {
                NotificationCenter.default.post(
                    name: .firmwareVersionUpdated,
                    object: nil,
                    userInfo: [
                        "deviceId": deviceId
                    ]
                )
            }
        }

        registerMessageHandler(WebViewMessageType.requestActivePromotion.rawValue) { webView, data in
            guard let params = data as? [String: Any],
                  let callbackName = params["callbackName"] as? String else {
                return
            }

            AppPromotionManager.shared.refresh { promotion in
                webView.callH5(
                    funcName: callbackName,
                    data: promotion.responseData
                )
            }
        }

        registerMessageHandler(WebViewMessageType.requestMarkPromotionRead.rawValue) { webView, data in
            guard let params = data as? [String: Any],
                  let callbackName = params["callbackName"] as? String else {
                return
            }

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
    
    func registerSchemeHandlers() {
        registerSchemeHandler(WebViewSchemeType.notify.rawValue) { view, url, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notifyName), object: nil, userInfo: param)
            }
        }
    }
    
    private func refreshDeviceList () {
        if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
            listViewController.getKeysFromServer()
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
