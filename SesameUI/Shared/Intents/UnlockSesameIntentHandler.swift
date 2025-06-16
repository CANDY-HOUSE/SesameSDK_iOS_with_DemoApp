//
//  UnlockSesameIntentHandler.swift
//  SesameIntents
//
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Intents
#if os(iOS)
import SesameSDK
//import Reachability
#else
import SesameWatchKitSDK
#endif

class UnlockSesameIntentHandler: NSObject, UnlockSesameIntentHandling {
    func resolveName(for intent: UnlockSesameIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(devices) = getResult, let sesameLock = devices.data.filter({$0.deviceName.lowercased() == intent.name?.lowercased() && $0 is CHSesameLock}).first {
                completion(INStringResolutionResult.success(with: sesameLock.deviceName))
            } else {
                completion(INStringResolutionResult.confirmationRequired(with: intent.name))
            }
        }
    }
    
    func handle(intent: UnlockSesameIntent, completion: @escaping (UnlockSesameIntentResponse) -> Void) {
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
                        self.unlockCHDevice(sesameLock, completion: completion)
                    } else {
                        device.connect(result: { _ in })
                    }
                }
                RunLoop.current.run()
            } else {
                completion(.failure(name: intent.name ?? ""))
            }
        }
    }
    
    func unlockCHDevice(_ device: CHSesameLock, completion: @escaping (UnlockSesameIntentResponse) -> Void) {
        let complete = {
            CHBluetoothCenter.shared.disableScan(){res in}
            CHBluetoothCenter.shared.disConnectAll{res in}
            completion(UnlockSesameIntentResponse.success(name: device.deviceName))
        }
        if let sesameLock = device as? CHSesame5 {
            sesameLock.unlock(historytag: device.hisTag) { _ in
                complete()
            }
            sesameLock.setAutoUnlockFlag(false) //[joi todo]??
            return
        } else if let sesameLock = device as? CHSesame2 {
            sesameLock.unlock { _ in
                complete()
            }
            sesameLock.setAutoUnlockFlag(false)
            return
        } else if let sesameLock = device as? CHSesameBike {
            sesameLock.unlock { _ in
                complete()
            }
            return
        } else if let sesameLock = device as? CHSesameBike2 {
            sesameLock.unlock { _ in
                complete()
            }
            return
        }
        // Bot 不支援解鎖
        completion(UnlockSesameIntentResponse.failure(name: "\(device.productModel.deviceModel()) is not supported"))
    }
}
