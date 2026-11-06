import Foundation
import SesameSDK
import SQLite3

enum LegacyMigration {
    private static let appGroup = "group.candyhouse.widget"
    private static let namesMigratedKey = "legacyNamesMigrated"

    static func run() {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else { return }
        migrateKeys(container.appendingPathComponent("CHDeviceModel.sqlite"))
        let uiStore = container.appendingPathComponent("SesameUI.sqlite")
        protect(uiStore)
        if !UserDefaults.standard.bool(forKey: namesMigratedKey), migrateNames(uiStore) {
            UserDefaults.standard.set(true, forKey: namesMigratedKey)
        }
    }

    /// The old store is deleted only after every key was written to the Keychain and read back.
    private static func migrateKeys(_ store: URL) {
        guard FileManager.default.fileExists(atPath: store.path) else { return }
        protect(store)
        guard let rows = query(store, "SELECT ZDEVICEUUID, ZDEVICEMODEL, ZHISTORYTAG, ZKEYINDEX, ZSECRETKEY, ZSESAME2PUBLICKEY FROM ZCHDEVICE") else { return }
        for row in rows {
            guard let id = (row[0] as? String).flatMap(UUID.init(uuidString:)), let model = row[1] as? String,
                  let keyIndex = row[3] as? String, let secretKey = row[4] as? String, let publicKey = row[5] as? String else { continue }
            let key = CHDeviceKey(deviceUUID: id, deviceModel: model, historyTag: row[2] as? Data,
                                  keyIndex: keyIndex, secretKey: secretKey, sesame2PublicKey: publicKey)
            if KeyStore.shared.key(id.uuidString) == nil, !KeyStore.shared.write(key) { return }
        }
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: store.path + suffix))
        }
    }

    private static func migrateNames(_ store: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: store.path) else { return true }
        guard let rows = query(store, "SELECT ZDEVICEID, ZNAME, ZKEYLEVEL FROM ZSESAMEDEVICE") else { return false }
        for row in rows {
            guard let id = uuid(row[0]) else { continue }
            KeyHandoff.rememberLegacy(id: id.uuidString, name: row[1] as? String, level: (row[2] as? Int64).map(Int.init))
        }
        for row in query(store, "SELECT ZDEVICEID, ZAUTOUNLOCKFLAG, ZLATITUDE, ZLONGITUDE, ZRADIUS FROM ZSESAMEDEVICE") ?? [] {
            guard let id = uuid(row[0]) else { continue }
            AutoUnlock.shared.rememberLegacy(id.uuidString, enabled: (row[1] as? Int64 ?? 0) != 0,
                                             latitude: row[2] as? Double ?? 0, longitude: row[3] as? Double ?? 0, radius: row[4] as? Double ?? 0)
        }
        return true
    }

    private static func uuid(_ value: Any?) -> UUID? {
        guard let bytes = value as? Data, bytes.count == 16 else { return nil }
        return bytes.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }

    private static func protect(_ store: URL) {
        for suffix in ["", "-wal", "-shm"] {
            let path = store.path + suffix
            guard FileManager.default.fileExists(atPath: path) else { continue }
            try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: path)
        }
    }

    private static func query(_ store: URL, _ sql: String) -> [[Any?]]? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(store.path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        var rows: [[Any?]] = []
        while true {
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE { break }
            guard step == SQLITE_ROW else { return nil }
            rows.append((0..<sqlite3_column_count(statement)).map { column -> Any? in
                switch sqlite3_column_type(statement, column) {
                case SQLITE_TEXT:
                    return sqlite3_column_text(statement, column).map { String(cString: $0) }
                case SQLITE_INTEGER:
                    return sqlite3_column_int64(statement, column)
                case SQLITE_FLOAT:
                    return sqlite3_column_double(statement, column)
                case SQLITE_BLOB:
                    guard let bytes = sqlite3_column_blob(statement, column) else { return Data() }
                    return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, column)))
                default:
                    return nil
                }
            })
        }
        return rows
    }
}
