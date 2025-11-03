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
    case requestRefresh = "requestRefresh"
    case requestDeviceInfo = "requestDeviceInfo"
    case requestDeviceName = "requestDeviceName"
    case requestDeviceRename = "requestDeviceRename"
    case requestAutoLayoutHeight = "requestAutoLayoutHeight"
}

enum WebViewSchemeType: String {
    case notify = "ssm://UI/webview/notify"
    case registNotify = "ssm://UI/webview/registNotify"
}

extension CHWebView {
    func registerMessageHandlers() {
        registerMessageHandler(WebViewMessageType.requestDeviceList.rawValue) { webView, data in
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
        
        registerMessageHandler(WebViewMessageType.requestDeviceName.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String,
               let deviceUUID = requestData["deviceUUID"] as? String {
                CHDeviceManager.shared.getCHDevices { result in
                    if case let .success(devices) = result {
                        if let device = devices.data.first(where:  { $0.deviceId.uuidString == deviceUUID } ) {
                            webView.callH5(funcName: callbackName, data: [
                                deviceUUID: device.deviceName
                            ])
                        }
                    }
                }
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestDeviceRename.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let deviceName = requestData["deviceName"] as? String,
               let deviceUUID = requestData["deviceUUID"] as? String,
               let callbackName = requestData["callbackName"] as? String {
                CHDeviceManager.shared.getCHDevices { result in
                    if case let .success(devices) = result {
                        if let device = devices.data.first(where:  { $0.deviceId.uuidString == deviceUUID } ) {
                            device.setDeviceName(deviceName)
                            webView.callH5(funcName: callbackName, data: [
                                "success": true
                            ])

                        }
                    }
                }
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestDeviceInfo.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let deviceUUID = requestData["deviceUUID"] as? String,
               let callbackName = requestData["callbackName"] as? String {
                CHDeviceManager.shared.getCHDevices { result in
                    if case let .success(devices) = result {
                        if let device = devices.data.first(where:  { $0.deviceId.uuidString == deviceUUID } ) {
                            let deviceKey = device.getKey()
                            let jsonData = try! JSONEncoder().encode(deviceKey)
                            var jsonObj = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
                            jsonObj["keyLevel"] = device.keyLevel
                            webView.callH5(funcName: callbackName, data: jsonObj)
                        }
                    }
                }
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
}
