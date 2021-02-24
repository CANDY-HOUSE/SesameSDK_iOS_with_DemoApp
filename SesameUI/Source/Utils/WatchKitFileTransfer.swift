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

final class WatchKitFileTransfer: NSObject, WCSessionDelegate {
    static let shared = WatchKitFileTransfer()
    
    override private init() {
        super.init()
        guard WCSession.isSupported() == true else {
            return
        }
        WCSession.default.delegate = self
    }

    func transferKeysToWatch() {
        guard WCSession.isSupported() == true else {
            return
        }
        
        var userInfo = [String: [String]]()
        var keys = [String]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                let keyDevices = devices.data.filter {
                    $0 is CHSesame2 || $0 is CHSesameBot || $0 is CHSesameBike
                }
                for keyDevice in keyDevices {
                    guard let deviceKey = keyDevice.getKey(),
                          let qrCodeURL = URL.qrCodeURLFromDeviceKey(deviceKey, deviceName: keyDevice.deviceName) else {
                        continue
                    }
                    let file = WatchKitFile(deviceId: keyDevice.deviceId.uuidString,
                                            key: qrCodeURL,
                                            name: keyDevice.deviceName,
                                            historyTag: Sesame2Store.shared.getHistoryTagString())
                    
                    let encoder = JSONEncoder()
                    let data = try! encoder.encode(file)
                    let jsonString = String(data: data, encoding: .utf8)!
                    keys.append(jsonString)
                }
                userInfo["keys"] = keys
                L.d("⌚️", "transferKeysToWatch", userInfo)
                WCSession.default.transferUserInfo(userInfo)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        L.d("⌚️", activationState, error ?? "")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        L.d("⌚️", "sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        L.d("⌚️", "sessionDidDeactivate")
    }
}
