import Foundation
import Security
import SesameSDK

final class KeyStore: CHKeyPersistence {
    static let shared = KeyStore()

    private let service = "co.candyhouse.sesame2.deviceKey"
    private let lock = NSLock()
    private var cache: [String: CHDeviceKey]?

    func all() -> [CHDeviceKey] {
        lock.lock()
        defer { lock.unlock() }
        return Array(loaded().values)
    }

    func key(_ deviceId: String) -> CHDeviceKey? {
        lock.lock()
        defer { lock.unlock() }
        return loaded()[deviceId.uppercased()]
    }

    func save(_ key: CHDeviceKey) {
        _ = write(key)
    }

    @discardableResult
    func write(_ key: CHDeviceKey) -> Bool {
        guard let data = try? JSONEncoder().encode(key) else { return false }
        let account = key.deviceUUID.uuidString.uppercased()
        lock.lock()
        defer { lock.unlock() }
        let query = baseQuery(account: account)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess, read(account: account) == data else { return false }
        if cache != nil { cache?[account] = key.copy() as? CHDeviceKey }
        return true
    }

    func delete(deviceId: UUID) {
        let account = deviceId.uuidString.uppercased()
        lock.lock()
        defer { lock.unlock() }
        SecItemDelete(baseQuery(account: account) as CFDictionary)
        cache?[account] = nil
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service] as CFDictionary)
        cache = [:]
    }

    private func baseQuery(account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    private func read(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private func loaded() -> [String: CHDeviceKey] {
        if let cache { return cache }
        var result: AnyObject?
        let status = SecItemCopyMatching([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnData as String: true
        ] as CFDictionary, &result)
        var keys: [String: CHDeviceKey] = [:]
        if status == errSecSuccess, let items = result as? [Data] {
            for data in items {
                guard let key = try? JSONDecoder().decode(CHDeviceKey.self, from: data) else { continue }
                keys[key.deviceUUID.uuidString.uppercased()] = key
            }
        }
        // Keychain is unreadable before the first unlock; do not cache an empty view of it.
        if status == errSecSuccess || status == errSecItemNotFound { cache = keys }
        return keys
    }
}
