import Foundation
import SesameSDK

enum KeyHandoff {
    private static let defaults = UserDefaults.standard
    private static let initializedKey = "keyHandoff.initialized"
    private static let pendingKey = "keyHandoff.pending"
    private static let visibleKey = "keyHandoff.visible"
    private static let orderKey = "keyHandoff.visibleOrder"
    private static let revisionKey = "keyHandoff.scopeRevision"

    static func initialize(hasLegacyUser: Bool) {
        guard !defaults.bool(forKey: initializedKey) else { return }
        defaults.set(hasLegacyUser ? [] : KeyStore.shared.all().map { $0.deviceUUID.uuidString.lowercased() }, forKey: pendingKey)
        defaults.set(true, forKey: initializedKey)
    }

    static func add(_ key: CHDeviceKey) {
        defaults.set(Array(pendingIds().union([key.deviceUUID.uuidString.lowercased()])), forKey: pendingKey)
    }

    static func acknowledge(_ id: String) {
        defaults.set(Array(pendingIds().subtracting([id.lowercased()])), forKey: pendingKey)
    }

    static func pending() -> [CHDeviceKey] {
        let ids = pendingIds()
        return KeyStore.shared.all().filter { ids.contains($0.deviceUUID.uuidString.lowercased()) }
    }

    static func key(_ id: String) -> CHDeviceKey? {
        KeyStore.shared.key(id)
    }

    static func isInScope(_ id: String) -> Bool {
        let id = id.lowercased()
        return pendingIds().contains(id) || (defaults.stringArray(forKey: visibleKey)?.contains(id) ?? false)
    }

    static func name(_ key: CHDeviceKey) -> String {
        defaults.string(forKey: "deviceName.\(key.deviceUUID.uuidString.lowercased())") ?? key.deviceModel
    }

    static func level(_ key: CHDeviceKey) -> Int {
        defaults.integer(forKey: "keyLevel.\(key.deviceUUID.uuidString.lowercased())")
    }

    static func rememberLegacy(id: String, name: String?, level: Int?) {
        let id = id.lowercased()
        if let name, !name.isEmpty, defaults.string(forKey: "deviceName.\(id)") == nil {
            defaults.set(name, forKey: "deviceName.\(id)")
        }
        if let level, defaults.object(forKey: "keyLevel.\(id)") == nil {
            defaults.set(level, forKey: "keyLevel.\(id)")
        }
    }

    static func saved() -> [CHDeviceKey] {
        let keys = KeyStore.shared.all()
        guard let visible = defaults.stringArray(forKey: visibleKey) else { return keys }
        let ids = Set(visible).union(pendingIds())
        return keys.filter { ids.contains($0.deviceUUID.uuidString.lowercased()) }
    }

    static func scopeRevision() -> Int {
        defaults.integer(forKey: revisionKey)
    }

    static func clearSavedScope() {
        defaults.set(scopeRevision() + 1, forKey: revisionKey)
        defaults.set([String](), forKey: visibleKey)
        defaults.removeObject(forKey: orderKey)
    }

    static func remember(_ rows: [[String: Any]]) {
        let ids = rows.compactMap { ($0["deviceUUID"] as? String)?.lowercased() }
        defaults.set(ids, forKey: visibleKey)
        defaults.set(ids, forKey: orderKey)
        for row in rows {
            guard let id = (row["deviceUUID"] as? String)?.lowercased() else { continue }
            defaults.set(row["deviceName"] as? String ?? row["deviceModel"] as? String, forKey: "deviceName.\(id)")
            defaults.set(row["keyLevel"] as? Int ?? 0, forKey: "keyLevel.\(id)")
        }
    }

    static func offlineDevices() -> [[String: Any]] {
        let order = defaults.stringArray(forKey: orderKey) ?? []
        let positions = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return saved()
            .sorted { (positions[$0.deviceUUID.uuidString.lowercased()] ?? .max) < (positions[$1.deviceUUID.uuidString.lowercased()] ?? .max) }
            .map { key in
                ["deviceUUID": key.deviceUUID.uuidString.uppercased(), "deviceModel": key.deviceModel, "deviceName": name(key), "keyLevel": level(key)]
            }
    }

    private static func pendingIds() -> Set<String> {
        Set(defaults.stringArray(forKey: pendingKey) ?? [])
    }
}
