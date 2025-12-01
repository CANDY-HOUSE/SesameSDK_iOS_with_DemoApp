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
    case requestDeviceList = "requestDeviceList"
    case requestRefresh = "requestRefresh"
    case requestDeviceInfo = "requestDeviceInfo"
    case requestDeviceName = "requestDeviceName"
    case requestDeviceRename = "requestDeviceRename"
    case requestAutoLayoutHeight = "requestAutoLayoutHeight"
    case requestLogin = "requestLogin"
    case requestPushToken = "requestPushToken"
    case requestNotificationStatus = "requestNotificationStatus"
    case requestNotificationSettings = "requestNotificationSettings"
    case updateRemote = "updateRemote"
    case addRemote = "addRemote"
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
        
        registerMessageHandler(WebViewMessageType.requestNotificationSettings.rawValue) { webView, data in
            if let _ = data as? [String: Any] {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        registerMessageHandler(WebViewMessageType.updateRemote.rawValue) { webView, data in
            if let requestData = data as? [String:Any],
               let hub3DeviceId = requestData["hub3DeviceId"] as? String,
               let remoteId = requestData["remoteId"] as? String,
               let alias = requestData["alias"] as? String {
                self.updateRemote(hub3DeviceId,remoteId:remoteId, alias:alias)
            }
        }
        registerMessageHandler(WebViewMessageType.addRemote.rawValue) { webView, data in
            if let requestData = data as? [String:Any],
               let hub3DeviceId = requestData["hub3DeviceId"] as? String,
               let remoteString = requestData["remote"] as? String {
                guard let jsonData = remoteString.data(using: .utf8) else { return }
                do {
                    let remote = try JSONDecoder().decode(IRRemote.self, from: jsonData)
                    self.addRemote(hub3DeviceId, remote: remote)
                } catch {
                    L.d("CHWebView","parse H5 addRemote Fail!")
                }
            }
        }
    }
    
    func updateRemote(_ hub3DeviceId:String, remoteId:String,alias:String) {
        let list = IRRemoteRepository.shared.getRemotesByKey(hub3DeviceId)
        for localRemote in list  {
            if (localRemote.uuid == remoteId) {
                localRemote.updateAlias(alias)
            }
        }
        IRRemoteRepository.shared.setRemotes(key: hub3DeviceId, remotes: list)
        if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
            listViewController.reloadTableView()
        }
    }
    
    
    func addRemote(_ hub3DeviceId:String, remote:IRRemote) {
        var list = IRRemoteRepository.shared.getRemotesByKey(hub3DeviceId)
        list.insert(remote, at: 0)
        IRRemoteRepository.shared.setRemotes(key: hub3DeviceId, remotes: list)
        if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
            listViewController.reloadTableView()
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
