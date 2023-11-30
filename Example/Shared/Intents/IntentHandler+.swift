//
//  SesameLock+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/02/05.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

//extension CHSesameLock {
//    func getShadowStatus() -> CHDeviceStatus? {
//        if let sesameLock = self as? CHSesame5 {
//            return sesameLock.deviceShadowStatus
//        } else if let sesameLock = self as? CHSesame2 {
//            return sesameLock.deviceShadowStatus
//        } else if let sesameLock = self as? CHSesameBot {
//            return sesameLock.deviceShadowStatus
//        } else if let sesameLock = self as? CHSesameBike {
//            return sesameLock.deviceShadowStatus
//        } else {
//            return nil
//        }
//    }
//}

extension URLSession {

    static func isInternetReachable(_ handler: @escaping (Bool)->Void) {
//        #if os(watchOS)
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.waitsForConnectivity = false
        urlSessionConfiguration.timeoutIntervalForRequest = 3.0
        let url = URL(string: "https://github.com/")!
        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            var chIsReachible = true
            if (error as NSError?)?.code == NSURLErrorNotConnectedToInternet ||
                (error as NSError?)?.code == NSURLErrorNetworkConnectionLost {
                chIsReachible = false
            }
            handler(chIsReachible)
        })
        task.resume()
        
    }
}
