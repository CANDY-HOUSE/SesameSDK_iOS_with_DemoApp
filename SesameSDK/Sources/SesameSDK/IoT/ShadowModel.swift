//
//  CHIoTResponse.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/24.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

struct CHDeviceShadow {
    var mechStatus: String?
    var wifiModule2s: [CHDeviceShadowWifiModule2]?
    
    static func fromData(_ data: Data) -> CHDeviceShadow {
        L.d("iotjs",String(data: data, encoding: .utf8))

        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//        L.d("iot json",json!)
        let state = json?["state"] as? [String: Any]
        let reported = state?["reported"] as? [String: Any]
        if let deviceShadowWifiModule2s = (reported?["wm2s"] as? [String:String])?.compactMap({ wm2Dic -> CHDeviceShadowWifiModule2 in
            let wm2Connection = wm2Dic.value == "00" ? false : true
            let wm2Id = wm2Dic.key
            return CHDeviceShadowWifiModule2(isConnected: wm2Connection, wifiModule2Id: wm2Id)
        }) {
            let shadow = CHDeviceShadow(mechStatus: reported?["mechst"] as? String,
                                        wifiModule2s: deviceShadowWifiModule2s)
            return shadow
        } else {
            let shadow = CHDeviceShadow(mechStatus: reported?["mechst"] as? String,
                                        wifiModule2s: nil)
            return shadow
        }
    }
    
    static func fromRESTFulData(_ data: Data) -> CHDeviceShadow? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        let deviceShadowWifiModule2s = (json["wm2s"] as? [String:String])?.compactMap({ wm2Dic -> CHDeviceShadowWifiModule2 in
            let wm2Connection = wm2Dic.value == "00" ? false : true
            let wm2Id = wm2Dic.key
            return CHDeviceShadowWifiModule2(isConnected: wm2Connection, wifiModule2Id: wm2Id)
        })
        let shadow = CHDeviceShadow(mechStatus: json["mechst"] as? String,
                                    wifiModule2s: deviceShadowWifiModule2s)
        return shadow
    }
}

struct CHDeviceShadowWifiModule2 {
    var isConnected: Bool
    var wifiModule2Id: String
}

protocol WifiModuleShadow {
    var isConnected: Bool? { get set }
    var ssks: String? { get set }
    var sesame2Keys: [String: String] { get }
    var v: String? { get set }
    static func fromData(_ data: Data) -> WifiModuleShadow
}

struct WifiModule2Shadow: WifiModuleShadow {
    var v: String? = nil
    var isConnected: Bool?
    var ssks: String?
    var sesame2Keys: [String: String] {
        get {
            guard let ssks = ssks, ssks.count > 0 else { return [:] }
            var hexStrings = [String]()
            for i in 0...ssks.count/46-1 {
                let base = 46*i
                let hexString = ssks.substring(with: base..<base+46)
                hexStrings.append(hexString)
            }
            var sesame2Keys = [String: String]()
            for key in hexStrings { // wm2影子有髒數據時，這裡會報錯造成閃退
                L.d("[ss5][ss5歷史？]",key.bytes.toHexString())
                guard key.count == 46 else {
                    continue
                }
                let keyHex = key.substring(with: 0..<44)
                let statusHex = key.substring(with: 44..<46)
                let keyB64 = String(data: keyHex.hexStringtoData(), encoding: .utf8)! + "=="
                if let idData = Data(base64Encoded: keyB64), let deviceID = idData.toHexString().noDashtoUUID() {
                    sesame2Keys[deviceID.uuidString] = statusHex
                }
            }
            return sesame2Keys
        }
    }
    
    static func fromData(_ data: Data) -> WifiModuleShadow {
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let state = json?["state"] as? [String: Any]
        let reported = state?["reported"] as? [String: Any]
        let wifiModule2Shadow = WifiModule2Shadow(isConnected: reported?["c"] as? Bool, ssks: reported?["ssks"] as? String)
        return wifiModule2Shadow
    }
}

struct Hub3Shadow : WifiModuleShadow {
    var v: String? = nil
    var isConnected: Bool?
    var ssks: String?
    var sesame2Keys: [String: String] {
        get {
            guard let ssks = ssks, ssks.count > 0 else { return [:] }
            var hexStrings = [String]()
            for i in 0...ssks.count/38-1 {
                let base = 38*i
                let hexString = ssks.substring(with: base..<base+38)
                hexStrings.append(hexString)
            }
            var sesame2Keys = [String: String]()
            for (index, key) in hexStrings.enumerated() { // wm2影子有髒數據時，這裡會報錯造成閃退
                L.d("[Hub3Shadow]",key.bytes.toHexString())
                let deviceId = key.substring(with: 0..<36)
//                let statusHex = key.substring(with: 36..<38)
                sesame2Keys[deviceId] = "\(index)"
            }
            return sesame2Keys
        }
    }
    // IR Remotes
    var irrs: String?
    
    static func fromData(_ data: Data) -> WifiModuleShadow {
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        L.d("hub3 iotjs", json as Any)
        let state = json?["state"] as? [String: Any]
        let reported = state?["reported"] as? [String: Any]
        let wifiModule2Shadow = Hub3Shadow(v:reported?["v"] as? String, isConnected: reported?["c"] as? Bool, ssks: reported?["ssks"] as? String, irrs: reported?["irrs"] as? String)
        return wifiModule2Shadow
    }
}
