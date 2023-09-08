////
////  SesameWatchKitSDKVersion.swift
////  SesameWatchKitSDK
////
////  Created by YuHan Hsiao on 2020/7/20.
////  Copyright © 2020 CandyHouse. All rights reserved.
////
//
//import Foundation
//
//public var Sesame2WatchKitSDKVersionString: String? {
//    get {
//        let bundle = Bundle(for: CandyhouseKeychainManager.self)
//        guard let path = bundle.path(forResource: "Info", ofType: "plist") else {
//            return nil
//        }
//        let url = URL(fileURLWithPath: path)
//        guard let infoPlist = NSDictionary(contentsOf: url) as? [String: Any] else {
//            return nil
//        }
//        return infoPlist["CFBundleShortVersionString"] as? String ?? nil
//    }
//}
//
//public var Sesame2WatchKitSDKBundleVersionString: String? {
//    get {
//        let bundle = Bundle(for: CandyhouseKeychainManager.self)
//        guard let path = bundle.path(forResource: "Info", ofType: "plist") else {
//            return nil
//        }
//        let url = URL(fileURLWithPath: path)
//        guard let infoPlist = NSDictionary(contentsOf: url) as? [String: Any] else {
//            return nil
//        }
//        return infoPlist["CFBundleVersion"] as? String ?? nil
//    }
//}
//
//public var Sesame2WatchKitSDKVersion: UInt? {
//    get {
//        guard let versionString = Sesame2WatchKitSDKVersionString else {
//            return nil
//        }
//        return UInt(versionString.remove(".")) ?? nil
//    }
//}
//
//public var Sesame2WatchKitSDKBundleVersion: UInt? {
//    get {
//        guard let versionString = Sesame2WatchKitSDKBundleVersionString else {
//            return nil
//        }
//        return UInt(versionString.remove(".")) ?? nil
//    }
//}
