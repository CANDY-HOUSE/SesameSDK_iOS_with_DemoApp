//
//  Notification+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let ApplicationWillResignActive = NSNotification.Name(rawValue: "applicationWillResignActive")
    static let ApplicationDidBecomeActive = NSNotification.Name(rawValue: "applicationDidBecomeActive")
    static let WCSessioinDidReceiveMessage = Notification.Name(rawValue: "WCSessioinDidReceiveMessage")
    static let SesameDeleted = Notification.Name(rawValue: "SesameDeleted")
    static let SesameRegistered = Notification.Name(rawValue: "SesameRegistered")
    static let UserLoggedIn = Notification.Name(rawValue: "UserLoggedIn")
    static let AddedFriends = Notification.Name(rawValue: "AddedFriends")
    static let SesamePropertyChanged = Notification.Name(rawValue: "SesamePropertyChanged")
}
