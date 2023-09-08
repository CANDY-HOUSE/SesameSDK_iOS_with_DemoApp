//
//  URLSession+.swift
//  SesameSDK
//  Created by Wayne Hsiao on 2020/8/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension URLSession {
    
    static private var chIsReachible: Bool?
    
    static func isInternetReachable(_ handler: @escaping (Bool)->Void) {
        if let isReachible = URLSession.chIsReachible {
            handler(isReachible)
        }
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        if #available(iOS 11.0, *) {
            urlSessionConfiguration.waitsForConnectivity = false
        }
    }
}
