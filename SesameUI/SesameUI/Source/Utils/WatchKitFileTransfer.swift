//
//  WatchKitFileTransfer.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import WatchConnectivity

/// 傳送鑰匙到手錶
final class WatchKitFileTransfer: NSObject, WCSessionDelegate {
    static let shared = WatchKitFileTransfer()
    
    override private init() {
        super.init()
        WCSession.default.delegate = self
    }
    
    func active() {
        guard isReachbleWatch() == true else { return }
        WCSession.default.activate()
    }
    
    private func isReachbleWatch() -> Bool {
        return WCSession.isSupported()
    }

    func transferKeysToWatch() {
        guard isReachbleWatch() == true else { return }
        var userInfo = [String: [String]]()
        var keys = [String]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                let keyDevices = devices.data.filter { $0 is CHSesameLock }
                for keyDevice in keyDevices {
                    guard let qrCodeURL = URL.qrCodeURLFromDevice(keyDevice, deviceName: keyDevice.deviceName, keyLevel: keyDevice.keyLevel) else {
                        continue
                    }
                    let file = WatchKitFile(deviceId: keyDevice.deviceId.uuidString,
                                            sesameQRCodeUrl: qrCodeURL,
                                            historyTag: keyDevice.getKey()?.historyTag ?? Data())
                    
                    let encoder = JSONEncoder()
                    let data = try! encoder.encode(file)
                    let jsonString = String(data: data, encoding: .utf8)!
                    keys.append(jsonString)
                }
                userInfo["sesameLocks"] = keys
                WCSession.default.transferUserInfo(userInfo)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        L.d(#function)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
//        L.d(#function)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
//        L.d(#function)
    }
}
