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
    case requestBLEConnect = "requestBLEConnect"
    case requestConfigureInternet = "requestConfigureInternet"
    case requestMonitorInternet = "requestMonitorInternet"
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
