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

final class WatchKitFileTransfer {
    static func transferKeysToWatch() {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                self.transferKeysToWatch(sesame2s: sesame2s.data)
            case .failure(let error):
                L.d("WatchKitFileTransfer.transferToWatch: \(error)")
            }
        }
    }
    
    private static func transferKeysToWatch(sesame2s: [CHSesame2]) {
        guard WCSession.isSupported() == true else {
            return
        }
        
        var keys = [String: [String: String]]()
        for sesame2 in sesame2s {
            var property = [String: String]()
            if let key = sesame2.getKey() {
                property["key"] = key
            }
            if let name = Sesame2Store.shared.getOrCreatePropertyOfSesame2(sesame2).name {
                property["name"] = name
            }
            if let historyTag = sesame2.getHistoryTag(),
                let historyTagString = String(data: historyTag, encoding: .utf8) {
                property["historyTag"] = historyTagString
            }
            keys[sesame2.deviceId.uuidString] = property
        }
        WCSession.default.transferUserInfo(keys)
        L.d("Sending \(keys.keys.count) keys to the watch.")
    }
}
