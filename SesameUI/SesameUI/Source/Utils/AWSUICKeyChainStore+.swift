//
//  KeyChainHelper.swift
//  SesameUI
//
//  Created by eddy on 2025/12/17.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import AWSCore

extension AWSUICKeyChainStore {
    func setBool(_ value: Bool, forKey key: String) {
        self.setString(value ? "true" : "false", forKey: key)
    }
    
    func boolValue(forKey key: String) -> Bool {
        return self.string(forKey: key) == "true"
    }
    
    func hasValue(forKey key: String) -> Bool {
        return self.string(forKey: key) != nil
    }
    
    static func instance(_ service: String? = nil) -> AWSUICKeyChainStore {
        let keychain = AWSUICKeyChainStore(service: service ?? Bundle.main.bundleIdentifier)
        return keychain
    }
}
