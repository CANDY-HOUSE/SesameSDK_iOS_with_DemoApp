////
////  SesameSDK2Version.swift
////  SesameSDK2
////
////  Created by YuHan Hsiao on 2020/7/20.
////  Copyright © 2020 CandyHouse. All rights reserved.
////
//
//import Foundation
//
//var Sesame2SDKVersionString: String? {
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
//var Sesame2SDKBundleVersionString: String? {
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
//var Sesame2SDKVersion: UInt? {
//    get {
//        guard let versionString = Sesame2SDKVersionString else {
//            return nil
//        }
//        return UInt(versionString.remove(".")) ?? nil
//    }
//}
//
//var Sesame2SDKBundleVersion: UInt? {
//    get {
//        guard let versionString = Sesame2SDKBundleVersionString else {
//            return nil
//        }
//        return UInt(versionString.remove(".")) ?? nil
//    }
//}
