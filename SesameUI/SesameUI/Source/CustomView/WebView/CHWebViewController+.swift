//
//  CHWebViewController+.swift
//  SesameUI
//
//  Created by eddy on 2025/9/30.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SesameSDK
import Foundation

enum WebViewMessageType: String {
    case requestDeviceList = "requestDeviceList"
}

enum WebViewSchemeType: String {
    case notify = "ssm://UI/webview/notify"
}

extension CHWebViewController {
    func registerMessageHandlers(webView: CHWebView) {
        webView.registerMessageHandler(WebViewMessageType.requestDeviceList.rawValue) { webView, data in
            var deviceList: [[String: String]] = []
            CHDeviceManager.shared.getCHDevices(result: { result in
                if case let .success(devices) = result {
                    deviceList = devices.data.compactMap { device in
                        return [
                            "deviceUUID": device.deviceId.uuidString,
                            "deviceName": device.deviceName,
                            "deviceModel": device.productModel.deviceModel(),
                            "keyLevel": "\(device.keyLevel)"
                        ]
                    }
                }
            })
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String {
                webView.callH5(funcName: callbackName, data: deviceList)
            }
        }
    }
    
    func registerSchemeHandlers(webView: CHWebView) {
        webView.registerSchemeHandler(WebViewSchemeType.notify.rawValue) { view, url, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notifyName), object: nil, userInfo: param)
            }
        }
    }
}
