//
//  AccountUserDefault.swift
//  SesameSDK
//
//  Created by Yiling on 2019/09/17.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation

struct AccountUserDefaults {
    var defaults: UserDefaults

    internal init() {
        defaults = UserDefaults.standard
    }

    static func setUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "username")
    }

    static func username() -> String? {
        return (UserDefaults.standard.value(forKey: "username") as? String) ?? nil
    }

    static func clearUsername() {
        UserDefaults.standard.removeObject(forKey: "username")
    }
}
