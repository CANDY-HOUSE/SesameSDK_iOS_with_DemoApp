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
        L.d("session didReceiveUserInfo")
        guard let keyProperties = userInfo as? [String: [String: String]] else {
            L.d("Receive keys error")
            return
        }
        let sesame2KeysString = keyProperties.compactMap {
            $0.value["key"]
        }

        var isNewDevices = true
        
        L.d("1. Get old deivces")
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesames):
                
                defer {
                    var isNewName = false
                    for sesame2 in sesames.data {
                        let key = sesame2.deviceId.uuidString
                        let propertyDic = userInfo[key] as? [String: String]
                        if let name = propertyDic?["name"], Sesame2Store.shared.getPropertyForDevice(sesame2).name != name {
                            Sesame2Store.shared.savePropertyForDevice(sesame2, withProperties: ["name": name])
                            isNewName = true
                            L.d("4. New names.")
                        }
                    }
                    if isNewName && isNewDevices {
                        self.receiveKeys(sesame2KeysString, userInfo: userInfo)
                    } else if isNewDevices {
                        self.receiveKeys(sesame2KeysString, userInfo: userInfo)
                    } else if isNewName {
                        NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
                    }
                }
                
                var haveNewDevice = false
                for currentDevice in sesames.data {
                    guard let propertyDic = userInfo[currentDevice.deviceId.uuidString] as? [String: String] else {
                        haveNewDevice = true
                        break
                    }
                    if propertyDic["key"] == currentDevice.getKey() {
                        haveNewDevice = true
                        break
                    }
                }
                
                guard haveNewDevice == true else {
                    L.d("No new devices.")
                    return
                }
                L.d("2. New deivces")
                self.dropOldDevices {
                    L.d("3. Receive keys: \(isNewDevices)")
                }

            case .failure(_):
                L.d("Receive keys error")
                break
            }
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
        CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: sesame2Keys) { result in
            switch result {
            case .success(_):
                NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: userInfo)
            case .failure(let error):
                L.d(error)
            }
        }
    }
}
