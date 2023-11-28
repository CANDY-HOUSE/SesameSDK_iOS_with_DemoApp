//
//  ToggleSesame2IntentHandler.swift
//  SesameIntents
//
//  Created by Wayne Hsiao on 2020/9/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Intents
import SesameSDK

class ToggleSesameIntentHandler: NSObject, ToggleSesameIntentHandling {
    func resolveName(for intent: ToggleSesameIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
//        L.d("[cut] resolveName")
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(devices) = getResult, let sesameLock = devices.data.filter({$0.deviceName.lowercased() == intent.name?.lowercased() && $0 is CHSesameLock}).first {
                completion(INStringResolutionResult.success(with: sesameLock.deviceName))
            } else {
                completion(INStringResolutionResult.confirmationRequired(with: intent.name))
            }
        }
    }
    
    func handle(intent: ToggleSesameIntent, completion: @escaping (ToggleSesameIntentResponse) -> Void) {
//        L.d("[cut] handle")
        CHBluetoothCenter.shared.enableScan { _ in }
        var reachability = false
        URLSession.isInternetReachable { isReachable in
            reachability = isReachable
        }
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(devices) = getResult,
               let device = devices.data.filter({$0.deviceName.lowercased() == intent.name?.lowercased() && $0 is CHSesameLock}).first, let sesameLock = device as? CHSesameLock {
                #if os(watchOS)
                sesameLock.getSesameLockStatus { _ in }       
                #endif
                let startTime = Date().timeIntervalSince1970
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    if Date().timeIntervalSince1970 - startTime > 10 {
                        CHExtensionListener.post(notification: CHExtensionListener.shortcutWillResignActive)
                        timer.invalidate()
                        completion(.failure(name: "\(intent.name!) time out"))
                        return
                    }
                    
                    // 藍牙登入就用藍芽開，如果藍芽沒登入但是影子有登入，就用wifi開。
                    if (reachability &&
                        sesameLock.deviceStatus.loginStatus == .unlogined &&
                        sesameLock.deviceShadowStatus?.loginStatus == .logined) ||
                        sesameLock.deviceStatus.loginStatus == .logined {
                        timer.invalidate()
                        self.toggleCHDevice(sesameLock, completion: completion)
                    } else {
                        device.connect(result: { _ in })
                    }
                }
                RunLoop.current.run()
            } else {
                CHExtensionListener.post(notification: CHExtensionListener.shortcutWillResignActive)
                completion(.failure(name: intent.name ?? ""))
            }
        }
    }
    
    func toggleCHDevice(_ device: CHSesameLock, completion: @escaping (ToggleSesameIntentResponse) -> Void) {
//        L.d("[cut] handle")
        let complete = {
            CHBluetoothCenter.shared.disableScan(){res in}
            CHBluetoothCenter.shared.disConnectAll{res in}
            CHExtensionListener.post(notification: CHExtensionListener.shortcutWillResignActive)
            completion(ToggleSesameIntentResponse.success(name: device.deviceName))
        }
        if let sesameLock = device as? CHSesame5 {
            sesameLock.toggle { _ in
                complete()
            }
            sesameLock.setAutoUnlockFlag(false)
            return
        } else if let sesameLock = device as? CHSesame2 {
            sesameLock.toggle { _ in
                complete()
            }
            sesameLock.setAutoUnlockFlag(false)
            return
        } else if let sesameLock = device as? CHSesameBot {
            sesameLock.click { _ in
                complete()
            }
            return
        }
        // Bike 不支援Toggle
        completion(ToggleSesameIntentResponse.failure(name: "\(device.productModel.deviceModel()) is not supported"))
    }
}
