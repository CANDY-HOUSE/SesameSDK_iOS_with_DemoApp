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

final class WatchKitFileTransfer: NSObject {
    
    static let shared = WatchKitFileTransfer()
    
    override init() {
        super.init()
        WCSession.default.delegate = self
     
    }
    
    func activate() {
        WCSession.default.activate()
    }
}

extension WatchKitFileTransfer: WCSessionDelegate {
    public func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        L.d("⌚️" ,"receiveUserInfoFromIPhone userInfo", userInfo["sesameLocks"]!)

        CHDeviceManager.shared.dropAllLocalKeys()

        // 解析 userInfo -> [WatchKitFile]
        let sesameLocks = (userInfo["sesameLocks"] as! [String]).map {
            try! JSONDecoder().decode(WatchKitFile.self, from: ($0).data(using: .utf8)!)
        }

        // 沒設備就把手錶設備清空
        guard let historyTagString = sesameLocks.first?.historyTag else {
            executeOnMainThread {
                SesameData.shared.devices = []
            }
            return
        }
        let historyTagData = "\(historyTagString)".data(using: .utf8)
        // [WatchKitFile] 轉成 [CHDeviceKey]
        let deviceKeys = sesameLocks.map { (item: WatchKitFile) -> CHDeviceKey in
            let urlString = item.sesameQRCodeUrl
            let url = URL(string: urlString)!
            let deviceKey = url.deviceKeyFromQRCodeURL()!
            deviceKey.historyTag = historyTagData
            return deviceKey
        }

        // 接收鑰匙
        CHDeviceManager.shared.receiveCHDeviceKeys(deviceKeys) { result in
            if case let .success(devices) = result {
                for device in devices.data {
                    let keyFile = sesameLocks.filter{$0.deviceId == device.deviceId.uuidString}.first!
                    let url = URL(string: keyFile.sesameQRCodeUrl)!
                    let keyLevelValue = Int(url.getQuery(name: "l"))!
                    let keyLevel = KeyLevel(rawValue: keyLevelValue)!
                    let deviceName = url.getQuery(name: "n")
                    device.setDeviceName(deviceName)
                    device.setKeyLevel(keyLevel.rawValue)
                }
                executeOnMainThread {
                    SesameData.shared.devices = devices.data
                }
            }
        }
    }
    

}
