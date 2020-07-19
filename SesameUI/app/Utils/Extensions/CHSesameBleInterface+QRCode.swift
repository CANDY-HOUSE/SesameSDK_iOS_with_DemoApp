//
//  Sesame2QRCode.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public enum CHQREvent: String {
    case sharedKey
}

enum CHQRKey: String {
    case QREventType = "t"
    case QRValue = "invite"
}

extension CHSesame2 {
    public func sesame2QRCodeURL() -> String? {
        guard let deviceKey = getKey() else {
                return nil
        }
        
        let sharedKey = CHQREvent.sharedKey.rawValue
        var components = URLComponents()
        components.scheme = URL.chURL.scheme
        components.host = URL.chURL.host
        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "t", value: sharedKey),
            URLQueryItem(name: sharedKey, value: deviceKey)
        ]
        return components.url?.absoluteString
    }
}

extension URL {
    
}
