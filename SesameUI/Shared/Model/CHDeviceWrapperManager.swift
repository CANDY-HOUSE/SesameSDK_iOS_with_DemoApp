//
//  CHDeviceWrapperManager.swift
//  SesameUI
//
//  Created by frey Mac on 2025/9/16.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

class CHDeviceWrapperManager {
    static let shared = CHDeviceWrapperManager()
    
    private var userKeyMap: [String: CHUserKey] = [:]
    private let queue = DispatchQueue(label: "co.candyhouse.sesame2.devicewrapper", attributes: .concurrent)
    
    private init() {}
    
    // 批量更新 UserKeys
    func updateUserKeys(_ userKeys: [CHUserKey]) {
        queue.async(flags: .barrier) {
            userKeys.forEach { userKey in
                let deviceId = userKey.deviceUUID.uppercased()
                self.userKeyMap[deviceId] = userKey
            }
        }
    }
    
    // 获取 UserKey
    func getUserKey(for deviceId: String) -> CHUserKey? {
        queue.sync {
            return userKeyMap[deviceId.uppercased()]
        }
    }
    
    // 清理
    func clear() {
        queue.async(flags: .barrier) {
            self.userKeyMap.removeAll()
        }
    }
}
