//
//  KeychainManager.swift
//  sesame-sdk-test-app
//
//  Created by YuHan Hsiao on 2020/5/7.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import KeychainSwift

public final class CHUIKeychainManager {
    public static let shared = CHUIKeychainManager()
    private let keychain = KeychainSwift()
    
    init() {
        keychain.accessGroup = "59M5HB7F95.group.candyhouse.widget"
    }
        
    @discardableResult
    public func setUsername(_ username: String, password: String) -> Bool {
        keychain.set(username, forKey: "current username") &&
        keychain.set(password, forKey: "current password")
    }
    
    public func getUsernameAndPassword() -> (username: String?, password: String?) {
        if let username = keychain.get("current username"),
            let password = keychain.get("current password") {
            return (username, password)
        } else {
            return (nil, nil)
        }
    }
    
    @discardableResult
    public func removeUsernameAndPassword() -> Bool {
        keychain.delete("current username") && keychain.delete("current password")
    }
    
    @discardableResult
    public func setWidgetNeedSignIn(_ bool: Bool) -> Bool {
        keychain.set(bool, forKey: "widgetNeed signIn")
    }
    
    public func isWidgetNeedSignIn() -> Bool? {
        keychain.getBool("widgetNeed signIn")
    }
}
