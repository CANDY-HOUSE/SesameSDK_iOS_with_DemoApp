//
//  BotScriptStore.swift
//  SesameUI
//
//  Created by frey Mac on 2026/3/18.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

final class BotScriptStore {
    static let shared = BotScriptStore()

    struct ScriptMeta {
        let alias: String?
        let displayOrder: Int?
    }

    private var map: [String: [Int: ScriptMeta]] = [:]
    private let queue = DispatchQueue(label: "co.candyhouse.sesame2.botscriptstore", attributes: .concurrent)

    private init() {}

    func merge(deviceUUID: String, data: [Int: ScriptMeta]) {
        let key = deviceUUID.uppercased()
        queue.async(flags: .barrier) {
            var inner = self.map[key] ?? [:]
            for (idx, meta) in data {
                let old = inner[idx]
                inner[idx] = ScriptMeta(
                    alias: meta.alias ?? old?.alias,
                    displayOrder: meta.displayOrder ?? old?.displayOrder
                )
            }
            self.map[key] = inner
        }
    }

    func putAlias(deviceUUID: String, actionIndex: Int, alias: String) {
        let key = deviceUUID.uppercased()
        queue.async(flags: .barrier) {
            var inner = self.map[key] ?? [:]
            let old = inner[actionIndex]
            inner[actionIndex] = ScriptMeta(
                alias: alias,
                displayOrder: old?.displayOrder
            )
            self.map[key] = inner
        }
    }

    func getAlias(deviceUUID: String, actionIndex: Int) -> String? {
        queue.sync {
            map[deviceUUID.uppercased()]?[actionIndex]?.alias
        }
    }

    func getDisplayOrder(deviceUUID: String, actionIndex: Int) -> Int? {
        queue.sync {
            map[deviceUUID.uppercased()]?[actionIndex]?.displayOrder
        }
    }

    func clear(deviceUUID: String) {
        queue.async(flags: .barrier) {
            self.map.removeValue(forKey: deviceUUID.uppercased())
        }
    }
}
