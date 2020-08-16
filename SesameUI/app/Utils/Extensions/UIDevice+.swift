//
//  UIDevice+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/7.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreLocation
import SystemConfiguration.CaptiveNetwork
import UIKit

extension UIDevice {
    @objc var WiFiSSID: String? {
        
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        
        let key = kCNNetworkInfoKeySSID as String
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? else { continue }
            return interfaceInfo[key] as? String
        }
        return nil
    }
}
