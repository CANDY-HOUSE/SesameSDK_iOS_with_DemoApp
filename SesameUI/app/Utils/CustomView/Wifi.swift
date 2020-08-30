//
//  Wifi.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension WifiModule2WifiInformation {
    func ssidName() -> String? {
        guard let ssid = ssid else {
            return nil
        }
        return String(data: ssid, encoding: .utf8)
    }
}

struct Wifi {
    var id: UUID
    var password: String?
    var wifiInformation: WifiModule2WifiInformation
}
