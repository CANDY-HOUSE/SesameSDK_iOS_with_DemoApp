//
//  WatchKitFileTransfer.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameWatchKitSDK
import WatchConnectivity

final class WatchKitFileTransfer {

    static func receiveUserInfoFromIPhone(_ userInfo: [String: Any]) {
//        L.d(" ⌚️ session didReceiveUserInfo")
        
//        L.d("1. ⌚️ Get old deivces")
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesames):
                
                let sesame2s = sesames.data
                var haveNewDevice = sesame2s.count > 0 ? false : true
                
                for currentDevice in sesame2s {
                    guard let propertyDic = userInfo[currentDevice.deviceId.uuidString] as? [String: String] else {
                        haveNewDevice = true
                        break
                    }
                    if propertyDic["key"] != currentDevice.getKey() {
                        haveNewDevice = true
                        break
                    }
                    if propertyDic["historyTag"] != String(data: currentDevice.getHistoryTag()!,
                                                           encoding: .utf8) {
                        haveNewDevice = true
                        break
                    }
                }
                
                guard haveNewDevice == true else {
//                    L.d("⌚️ No new devices.")
                    updateSesame2Name(sesames.data, userInfo: userInfo, hasNewDevice: false)
                    return
                }
//                L.d("2. ⌚️ New deivces")
                self.dropOldDevices {
//                    L.d("3. ⌚️ Receive keys")
                    updateSesame2Name(sesames.data, userInfo: userInfo, hasNewDevice: true)
                }

            case .failure(_):
                L.d("Receive keys error")
                break
            }
        }
    }
    
    private static func updateSesame2Name(_ sesame2s: [CHSesame2], userInfo: [String: Any], hasNewDevice: Bool) {
        guard let keyProperties = userInfo as? [String: [String: String]] else {
            L.d("Receive keys error")
            return
        }
        let sesame2KeysString = keyProperties.compactMap {
            $0.value["key"]
        }
        
        var isNewName = false
        
        for sesame2 in sesame2s {
            
            let key = sesame2.deviceId.uuidString
            let propertyDic = userInfo[key] as? [String: String]
            if let name = propertyDic?["name"], Sesame2Store.shared.getSesame2Property(sesame2)?.name != name {
                Sesame2Store.shared.savePropertyToDevice(sesame2, withProperties: ["name": name])
                isNewName = true
//                L.d("4. ⌚️ New names.", Sesame2Store.shared.getSesame2Property(sesame2)?.name)
            }
        }
        if isNewName && hasNewDevice {
            self.receiveKeys(sesame2KeysString, userInfo: userInfo)
        } else if hasNewDevice {
            self.receiveKeys(sesame2KeysString, userInfo: userInfo)
        } else if isNewName {
            NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
        }
    }
    
    private static func dropOldDevices(_ completeHandler: @escaping ()->Void) {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame2 in sesame2s.data {
                    sesame2.dropKey(){res in}
                    Sesame2Store.shared.deletePropertyAndHisotryForDevice(sesame2)
                }
                completeHandler()
            case .failure(_):
                break
            }
        }
    }
    
    private static func receiveKeys(_ sesame2Keys: [String], userInfo: [String : Any]) {
        
        let tokenFetchLock = DispatchGroup()
        
        CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: sesame2Keys) { result in
            switch result {
            case .success(let sesame2):
                
                for sesame2 in sesame2.data {
                    var encodedHistoryTag = "ドラえもん⌚️".data(using: .utf8)!
                    if let propertyDic = userInfo[sesame2.deviceId.uuidString] as? [String: String],
                        let historyTag = propertyDic["historyTag"] {
                        let watchHistoryTag = "\(historyTag)\("⌚️")".data(using: .utf8)!
                        encodedHistoryTag = watchHistoryTag.count > 21 ? historyTag.data(using: .utf8)! : watchHistoryTag
                    }
                    tokenFetchLock.enter()
                    sesame2.setHistoryTag(encodedHistoryTag) {_ in
                        tokenFetchLock.leave()
                    }
                }

                tokenFetchLock.wait()
                
                NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
            case .failure(let error):
                L.d(error)
            }
        }
    }
}
