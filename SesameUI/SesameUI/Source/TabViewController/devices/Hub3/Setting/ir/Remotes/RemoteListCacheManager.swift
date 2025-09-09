//
//  RemoteListCacheManager.swift
//  SesameUI
//
//  Created by wuying on 2025/9/8.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

class RemoteListCacheManager {
    static let shared = RemoteListCacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "RemoteListCache_"
    
    private init() {}
    
    // MARK: - Cache Key Generation
    private func cacheKey(for irType: Int) -> String {
        return "\(cacheKeyPrefix)\(irType)"
    }
    
    private func timestampKey(for irType: Int) -> String {
        return "\(cacheKeyPrefix)\(irType)_timestamp"
    }
    
    // MARK: - Cache Operations
    
    /// 保存遥控器列表到缓存
    func saveRemoteList(_ remoteList: [IRRemote], for irType: Int) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(remoteList)
            
            userDefaults.set(data, forKey: cacheKey(for: irType))
            userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey(for: irType))
            userDefaults.synchronize()
            
            L.d("[IRRemoteCacheManager] 缓存保存成功 - irType: \(irType), count: \(remoteList.count)")
        } catch {
            L.d("[IRRemoteCacheManager] 缓存保存失败: \(error)")
        }
    }
    
    /// 从缓存获取遥控器列表
    func getRemoteList(for irType: Int) -> [IRRemote]? {
        guard let data = userDefaults.data(forKey: cacheKey(for: irType)) else {
            L.d("[IRRemoteCacheManager] 缓存不存在 - irType: \(irType)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let remoteList = try decoder.decode([IRRemote].self, from: data)
            L.d("[IRRemoteCacheManager] 缓存读取成功 - irType: \(irType), count: \(remoteList.count)")
            return remoteList
        } catch {
            L.d("[IRRemoteCacheManager] 缓存解析失败: \(error)")
            clearCache(for: irType)
            return nil
        }
    }
    
    /// 清除指定类型的缓存
    func clearCache(for irType: Int) {
        userDefaults.removeObject(forKey: cacheKey(for: irType))
        userDefaults.removeObject(forKey: timestampKey(for: irType))
        userDefaults.synchronize()
        L.d("[IRRemoteCacheManager] 缓存已清除 - irType: \(irType)")
    }
    
    /// 清除所有缓存
    func clearAllCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(cacheKeyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.synchronize()
        L.d("[IRRemoteCacheManager] 所有缓存已清除")
    }
    
    /// 获取缓存信息
    func getCacheInfo(for irType: Int) -> (exists: Bool, timestamp: Date?, count: Int) {
        let exists = userDefaults.data(forKey: cacheKey(for: irType)) != nil
        let timestampValue = userDefaults.double(forKey: timestampKey(for: irType))
        let timestamp = timestampValue > 0 ? Date(timeIntervalSince1970: timestampValue) : nil
        let count = getRemoteList(for: irType)?.count ?? 0
        
        return (exists, timestamp, count)
    }
    
    /// 检查缓存是否存在
    func hasCachedData(for irType: Int) -> Bool {
        return userDefaults.data(forKey: cacheKey(for: irType)) != nil
    }
}
