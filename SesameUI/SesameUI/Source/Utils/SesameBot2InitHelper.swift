//
//  SesameBot2InitHelper.swift
//  SesameUI
//
//  Created by frey Mac on 2026/3/18.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

enum Bot2InitHelper {
    
    static func initKey(_ device: CHSesameBot2) -> String {
        "\(device.deviceId.uuidString)_BotScriptInited"
    }
    
    static func currentScriptKey(_ device: CHSesameBot2) -> String {
        device.deviceId.uuidString
    }
    
    static func clearLocal(device: CHSesameBot2) {
        BotScriptStore.shared.clear(deviceUUID: device.deviceId.uuidString)
        UserDefaults.standard.removeObject(forKey: currentScriptKey(device))
        UserDefaults.standard.removeObject(forKey: initKey(device))
    }
    
    static func clearBotScript(device: CHSesameBot2, completion: ((Bool) -> Void)? = nil) {
        CHAPIClient.shared.clearBotScript(deviceUUID: device.deviceId.uuidString) { result in
            clearLocal(device: device)
            switch result {
            case .success(_):
                completion?(true)
            case .failure(_):
                completion?(false)
            }
        }
    }
    
    static func initDefaultsIfNeeded(device: CHSesameBot2) {
        let inited = UserDefaults.standard.bool(forKey: initKey(device))
        guard !inited else { return }
        
        let events = device.scripts.events
        guard events.isEmpty == false else { return }
        
        let deviceUUID = device.deviceId.uuidString
        let currentIndex = UserDefaults.standard.integer(forKey: currentScriptKey(device))
        
        let remoteMap = Dictionary(uniqueKeysWithValues:
                                    (device.stateInfo?.scriptList ?? []).compactMap { item -> (Int, BotScriptItem)? in
            guard let idx = Int(item.actionIndex) else { return nil }
            return (idx, item)
        }
        )
        
        let metaMap = Dictionary(uniqueKeysWithValues:
                                    events.enumerated().map { index, _ in
            let remote = remoteMap[index]
            let finalAlias = (remote?.alias?.isEmpty == false) ? remote!.alias! : "🎬 \(index)"
            let finalDisplayOrder = remote?.displayOrder ?? index
            return (index, BotScriptStore.ScriptMeta(alias: finalAlias, displayOrder: finalDisplayOrder))
        }
        )
        BotScriptStore.shared.merge(deviceUUID: deviceUUID, data: metaMap)
        
        let group = DispatchGroup()
        var hasWork = false
        var allSuccess = true
        
        for (index, _) in events.enumerated() {
            let remote = remoteMap[index]
            let needAlias = remote?.alias == nil || remote?.alias?.isEmpty == true
            let needDisplayOrder = remote?.displayOrder == nil
            let needDefault = remote?.isDefault == nil
            
            if !needAlias && !needDisplayOrder && !needDefault { continue }
            
            hasWork = true
            group.enter()
            
            let req = BotScriptRequest(
                deviceUUID: device.deviceId.uuidString.uppercased(),
                actionIndex: "\(index)",
                alias: needAlias ? "🎬 \(index)" : nil,
                isDefault: needDefault ? (index == currentIndex ? 1 : 0) : nil,
                actionData: nil,
                displayOrder: needDisplayOrder ? index : nil,
                deleteAll: nil,
                batchDisplayOrders: nil
            )
            
            CHAPIClient.shared.updateBotScript(req) { result in
                if case .failure(_) = result {
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        if !hasWork {
            UserDefaults.standard.set(true, forKey: initKey(device))
            return
        }
        
        group.notify(queue: .main) {
            if allSuccess {
                UserDefaults.standard.set(true, forKey: initKey(device))
            }
        }
    }
    
    static func forceInitDefaults(device: CHSesameBot2, completion: ((Bool) -> Void)? = nil) {
        let events = device.scripts.events
        guard events.isEmpty == false else {
            completion?(false)
            return
        }
        
        let deviceUUID = device.deviceId.uuidString
        let currentIndex = UserDefaults.standard.integer(forKey: currentScriptKey(device))
        
        let metaMap = Dictionary(uniqueKeysWithValues:
                                    events.enumerated().map { index, _ in
            (index, BotScriptStore.ScriptMeta(alias: "🎬 \(index)", displayOrder: index))
        }
        )
        BotScriptStore.shared.merge(deviceUUID: deviceUUID, data: metaMap)
        
        let group = DispatchGroup()
        var allSuccess = true
        
        for (index, _) in events.enumerated() {
            group.enter()
            
            let req = BotScriptRequest(
                deviceUUID: device.deviceId.uuidString.uppercased(),
                actionIndex: "\(index)",
                alias: "🎬 \(index)",
                isDefault: index == currentIndex ? 1 : 0,
                actionData: nil,
                displayOrder: index,
                deleteAll: nil,
                batchDisplayOrders: nil
            )
            
            CHAPIClient.shared.updateBotScript(req) { result in
                if case .failure(_) = result {
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if allSuccess {
                UserDefaults.standard.set(true, forKey: initKey(device))
            }
            completion?(allSuccess)
        }
    }
}
