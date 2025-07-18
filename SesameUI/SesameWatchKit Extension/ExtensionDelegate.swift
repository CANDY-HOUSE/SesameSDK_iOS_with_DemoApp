//
//  ExtensionDelegate.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/7/1.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import WatchConnectivity
import SesameWatchKitSDK
import CoreFoundation

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    override init() {
        L.d("⌚️", "init test3")
        // 配置 AWS
        AWSConfigManager.configure(with: AWSSharedConfig())
        // 啟動接收手機傳來的訊息
        WatchKitFileTransfer.shared.activate()
        
        let displayStatusChanged: CFNotificationCallback = { _, _, _, _, _ in
            let screenOff = isScreenOff()
            L.d("⌚️", "screen", screenOff == true ? "off" : "on")
            // 手錶螢幕關閉時收不到藍芽peripheral更新，因此斷開藍芽連線
            if screenOff {
                CHBluetoothCenter.shared.disableScan(){res in}
                CHBluetoothCenter.shared.disConnectAll(){res in}
            }
        }
        // 註冊手錶螢幕開關變化事件
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        nil, // observer
                                        displayStatusChanged, // callback
                                        "com.apple.iokit.hid.displayStatus" as CFString, // event name
                                        nil, // object
                                        CFNotificationSuspensionBehavior.deliverImmediately)
    }

    func applicationDidFinishLaunching() {
        L.d("⌚️", "applicationDidFinishLaunching")
    }
    
    func applicationWillEnterForeground() {
        L.d("⌚️", "applicationWillEnterForeground")
    }
    
    func applicationDidBecomeActive() {
        L.d("⌚️", "applicationDidBecomeActive")
        CHBluetoothCenter.shared.enableScan { _ in }
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                executeOnMainThread {
                    SesameData.shared.devices = devices.data
                }
            }
        }
    }
    
    func applicationWillResignActive() {
        L.d("⌚️", "applicationWillResignActive")
//        L.d("⌚️", #function, WKExtension.shared().applicationState.desc)
    }

    func applicationDidEnterBackground() {
        L.d("⌚️", "applicationDidEnterBackground")
        CHBluetoothCenter.shared.disableScan(){res in}
        CHBluetoothCenter.shared.disConnectAll(){res in}
    }
}
