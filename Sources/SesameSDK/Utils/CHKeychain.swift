//
//  CHKeychain.swift
//  SesameSDK
//
//  统一的 Keychain 读写封装（基于项目已有的 SwKeyStore），供上层复用。
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

public enum CHKeychain {
    public static func setString(_ value: String, forKey key: String) {
        try? SwKeyStore.upsertKey(value, keyTag: key)
    }

    public static func string(forKey key: String) -> String? {
        try? SwKeyStore.getKey(key)
    }

    public static func setBool(_ value: Bool, forKey key: String) {
        setString(value ? "true" : "false", forKey: key)
    }

    public static func boolValue(forKey key: String) -> Bool {
        string(forKey: key) == "true"
    }

    public static func remove(forKey key: String) {
        try? SwKeyStore.delKey(key)
    }
}
