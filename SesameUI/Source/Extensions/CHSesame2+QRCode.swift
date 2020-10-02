//
//  CHSesame2+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension CHSesame2 {
    public func sesame2QRCodeURL() -> String? {
        guard let deviceKey = getKey() else {
                return nil
        }
        
        let sharedKey = QRcodeType.sharedKey.rawValue
        var components = URLComponents()
        components.scheme = URL.sesame2UI.scheme
        components.host = URL.sesame2UI.host
        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "t", value: sharedKey),
            URLQueryItem(name: sharedKey, value: deviceKey)
        ]
        return components.url?.absoluteString
    }
}
