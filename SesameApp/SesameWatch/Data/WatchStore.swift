import Foundation
import SesameSDK

/// What the iPhone sent last (`WatchKeySync`). Keys go to the Keychain (`KeyStore`); names, gateways and history tags to UserDefaults.
enum WatchStore {
    struct Device: Identifiable {
        let id: String
        let model: String
        let name: String
        let kind: SesameDeviceKind
        /// The device is bound to a WM2 / Hub3, so its shadow is worth reading.
        let gateway: Bool
    }

    private static let defaults = UserDefaults.standard
    private static let devicesKey = "watch.devices"
    private static let historyKey = "watch.historyTag"
    private static let historyNameKey = "watch.historyName"

    /// Devices in the iPhone's order that still have a key.
    static func devices() -> [Device] {
        (defaults.array(forKey: devicesKey) as? [[String: Any]] ?? []).compactMap { row in
            guard let id = row["deviceUUID"] as? String, let model = row["deviceModel"] as? String,
                  let kind = SesameDeviceKind(model: model), KeyStore.shared.key(id) != nil else { return nil }
            return Device(id: id, model: model, name: row["deviceName"] as? String ?? model, kind: kind, gateway: row["gateway"] as? Bool ?? false)
        }
    }

    /// The account's environment id, recorded by OS3 devices and gateways.
    static var historyTag: Data {
        defaults.data(forKey: historyKey) ?? Data(repeating: 0xff, count: 16)
    }

    /// The account name, recorded by OS2 devices.
    static var historyName: Data? {
        defaults.data(forKey: historyNameKey)
    }

    /// Replaces everything with the iPhone's latest context; an empty list clears the Watch. A malformed context is ignored.
    @discardableResult
    static func apply(_ context: [String: Any]) -> Bool {
        guard let rows = context["devices"] as? [[String: Any]] else { return false }
        var keys: [CHDeviceKey] = []
        var stored: [[String: Any]] = []
        for row in rows {
            guard let id = (row["deviceUUID"] as? String).flatMap(UUID.init(uuidString:)), let model = row["deviceModel"] as? String,
                  let keyIndex = row["keyIndex"] as? String, let secretKey = row["secretKey"] as? String,
                  let publicKey = row["sesame2PublicKey"] as? String else { return false }
            keys.append(CHDeviceKey(deviceUUID: id, deviceModel: model, historyTag: nil, keyIndex: keyIndex, secretKey: secretKey, sesame2PublicKey: publicKey))
            stored.append([
                "deviceUUID": id.uuidString,
                "deviceModel": model,
                "deviceName": row["deviceName"] as? String ?? model,
                "gateway": row["gateway"] as? Bool ?? false
            ])
        }
        let incoming = Set(keys.map(\.deviceUUID))
        for key in KeyStore.shared.all() where !incoming.contains(key.deviceUUID) {
            KeyStore.shared.delete(deviceId: key.deviceUUID)
        }
        for key in keys {
            KeyStore.shared.write(key)
        }
        defaults.set(stored, forKey: devicesKey)
        defaults.set(context["historyTag"] as? Data, forKey: historyKey)
        defaults.set(context["historyName"] as? Data, forKey: historyNameKey)
        return true
    }
}
