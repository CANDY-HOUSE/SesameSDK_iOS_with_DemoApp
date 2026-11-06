import Foundation
import SesameSDK

final class BleController: NSObject {
    static let shared = BleController()

    var publish: (([[String: Any]]) -> Void)?
    private(set) var foreground = false
    private(set) var background = false
    private var intentRuns = 0
    private(set) lazy var peripheralSettings = PeripheralSettings(ble: self)
    private(set) lazy var hubSettings = HubSettings(ble: self)
    private var snapshotScheduled = false
    private(set) var cloudRows: [[String: Any]] = []
    private var order: [String] = []
    private var devices: [String: CHDevice] = [:]
    private var appliedKeys: [String: CHDeviceKey] = [:]
    private var batteries: [String: Int] = [:]
    private(set) var receivedCloudList = false
    private var shortcutDevices: [[String]]?
    private let defaults = UserDefaults.standard
    private lazy var history = Self.historyBytes(defaults.string(forKey: "environmentId"))
    // OS2 devices (Sesame 3/4, Bike 1, Bot 1) record a text tag: the account name supplied by Biz.
    private lazy var os2History: Data? = defaults.string(forKey: "historyName").flatMap { $0.isEmpty ? nil : Data($0.utf8) }

    private static func historyBytes(_ value: String?) -> Data {
        guard let value, let uuid = UUID(uuidString: value) else { return Data(repeating: 0xff, count: 16) }
        return withUnsafeBytes(of: uuid.uuid) { Data($0) }
    }

    func device(_ id: String) -> CHDevice? {
        devices[id.uppercased()]
    }

    func allDevices() -> [CHDevice] {
        order.compactMap { devices[$0] }
    }

    func restoreSaved() {
        guard devices.isEmpty, !receivedCloudList else { return }
        for key in KeyHandoff.saved() {
            add(key)
        }
        snapshot()
    }

    func accept(_ rows: [[String: Any]], historyTag: String?, historyName: String?) {
        var keys: [CHDeviceKey] = []
        for row in rows {
            guard let id = (row["deviceUUID"] as? String).flatMap(UUID.init(uuidString:)),
                  let model = row["deviceModel"] as? String, CHProductModel.deviceModeulFromString(model) != nil,
                  let keyIndex = row["keyIndex"] as? String, let secretKey = row["secretKey"] as? String,
                  let publicKey = row["sesame2PublicKey"] as? String else { return }
            keys.append(CHDeviceKey(deviceUUID: id, deviceModel: model, historyTag: nil, keyIndex: keyIndex, secretKey: secretKey, sesame2PublicKey: publicKey))
        }
        guard Set(keys.map(\.deviceUUID)).count == keys.count else { return }
        let incoming = Set(keys.map { $0.deviceUUID.uuidString.uppercased() })
        receivedCloudList = true
        cloudRows = rows
        KeyHandoff.remember(rows)
        let shortcuts = SesameDeviceEntity.all().map { [$0.id, $0.name] }
        if shortcuts != shortcutDevices {
            shortcutDevices = shortcuts
            SesameShortcuts.updateAppShortcutParameters()
        }
        // Keys not yet uploaded stay on disk; an empty list must not erase legacy guest keys.
        for id in order where !incoming.contains(id) {
            peripheralSettings.forget(id)
            hubSettings.forget(id)
            appliedKeys[id] = nil
            if let device = devices.removeValue(forKey: id) {
                detach(device)
                if device.isRegistered { device.disconnect { _ in } }
            }
        }
        order.removeAll { !incoming.contains($0) }
        if let historyTag, !historyTag.isEmpty {
            history = Self.historyBytes(historyTag)
            defaults.set(historyTag, forKey: "environmentId")
        } else if rows.isEmpty {
            history = Self.historyBytes(nil)
            defaults.removeObject(forKey: "environmentId")
        }
        if let historyName, !historyName.isEmpty {
            os2History = Data(historyName.utf8)
            defaults.set(historyName, forKey: "historyName")
        } else if rows.isEmpty {
            os2History = nil
            defaults.removeObject(forKey: "historyName")
        }
        BleBackend.shared.gatewayDevices = Set(rows.filter { ($0["stateInfo"] as? [String: Any])?["wm2State"] as? Bool == true }
            .compactMap { ($0["deviceUUID"] as? String)?.uppercased() })
        for key in keys {
            let id = key.deviceUUID.uuidString.uppercased()
            if let previous = appliedKeys[id], previous.deviceModel == key.deviceModel, previous.keyIndex == key.keyIndex,
               previous.secretKey == key.secretKey, previous.sesame2PublicKey == key.sesame2PublicKey { continue }
            guard KeyStore.shared.write(key) else { continue }
            add(key)
        }
        order = keys.map { $0.deviceUUID.uuidString.uppercased() }.filter { devices[$0] != nil }
        snapshot()
        AutoUnlock.shared.sync()
        WatchKeySync.shared.push()
    }

    private func add(_ key: CHDeviceKey) {
        guard let device = CHBluetoothCenter.shared.restoreDevice(key) else { return }
        let id = key.deviceUUID.uuidString.uppercased()
        appliedKeys[id] = key
        if devices[id] == nil { order.append(id) }
        devices[id] = device
        device.delegate = self
        if !device.multicastDelegate.containsDelegate(self) { device.multicastDelegate.addDelegate(self) }
        connect(device)
    }

    private func detach(_ device: CHDevice) {
        if device.delegate === self { device.delegate = nil }
        device.multicastDelegate.removeDelegate(self)
    }

    func connect(_ device: CHDevice) {
        guard foreground || background || intentRuns > 0, !BleFirmwareUpdate.shared.active(device.uuid), device.deviceStatus == .receivedBle() else { return }
        let wanted = device is CHSesameLock ||
            (foreground && peripheralSettings.shouldConnect(device)) ||
            (foreground && device is CHWifiModule2 && hubSettings.watching(device.uuid))
        if wanted { device.connect { _ in } }
    }

    /// Auto-unlock keeps scanning after leaving home so the lock is found on arrival.
    func startBackground() {
        guard !background else { return }
        background = true
        CHBluetoothCenter.shared.statusDelegate = self
        CHBluetoothCenter.shared.enableScan { _ in }
        reconnect()
    }

    func stopBackground() {
        background = false
        if !foreground && intentRuns == 0 { CHBluetoothCenter.shared.disableScan { _ in } }
    }

    /// Siri may run while the app is in the background: scan and log in until the command is done.
    func startIntent() {
        intentRuns += 1
        CHBluetoothCenter.shared.statusDelegate = self
        CHBluetoothCenter.shared.enableScan { _ in }
        reconnect()
    }

    /// Like the native Siri extension, a background run releases the locks so other phones can connect.
    func stopIntent() {
        intentRuns -= 1
        guard intentRuns == 0, !foreground, !background else { return }
        CHBluetoothCenter.shared.disableScan { _ in }
        devices.values.forEach { $0.disconnect { _ in } }
    }

    func saveModel(_ device: CHDevice, _ model: CHProductModel) {
        guard let key = appliedKeys[device.uuid] else { return }
        let updated = CHDeviceKey(deviceUUID: key.deviceUUID, deviceModel: model.deviceModel(), historyTag: key.historyTag,
                                  keyIndex: key.keyIndex, secretKey: key.secretKey, sesame2PublicKey: key.sesame2PublicKey)
        if KeyStore.shared.write(updated) { appliedKeys[device.uuid] = updated }
        snapshot()
    }

    func resume() {
        CHBluetoothCenter.shared.statusDelegate = self
        foreground = true
        CHBluetoothCenter.shared.enableScan { _ in }
        devices.values.forEach(connect)
        snapshot()
    }

    func pause() {
        foreground = false
        if !background && intentRuns == 0 { CHBluetoothCenter.shared.disableScan { _ in } }
        hubSettings.endGrace()
    }

    func reconnect() {
        devices.values.forEach(connect)
    }

    func close() {
        peripheralSettings.close()
        hubSettings.close()
        pause()
        for device in devices.values {
            detach(device)
            device.disconnect { _ in }
        }
        devices.removeAll()
        order.removeAll()
        appliedKeys.removeAll()
        receivedCloudList = false
        cloudRows = []
        BleBackend.shared.gatewayDevices = []
        snapshot()
    }

    func historyTag() -> Data { history }
    // OS3 lock, unlock and click tags start with the iOS BLE type (UUID4HistoryTagType 15), as in the native app.
    func os3HistoryTag() -> Data { Data([0x00, 0x0f]) + history }
    func os2HistoryTag() -> Data? { os2History }
    // Gateway commands use the iOS Wi-Fi type (UUID4HistoryTagType 17) for every model, as Biz does in the app.
    func gatewayHistoryTag() -> Data { Data([0x00, 0x11]) + history }

    /// Coalesces the many SDK notifications of one run loop pass into one bridge message.
    func snapshot() {
        guard !snapshotScheduled else { return }
        snapshotScheduled = true
        DispatchQueue.main.async {
            self.snapshotScheduled = false
            self.publishSnapshot()
        }
    }

    private func publishSnapshot() {
        let bluetoothOff = CHBluetoothCenter.shared.scanning == .bleClose()
        let rows: [[String: Any]] = order.compactMap { id in
            guard let device = devices[id] else { return nil }
            let connected = device.deviceStatus.loginStatus == .logined
            var row: [String: Any] = [
                "deviceUUID": id,
                "bleConnected": connected,
                "bluetoothOff": bluetoothOff,
                "bleState": device.deviceStatus.webBleState,
                "showBle": device is CHSesameLock,
                "position": connected && (device is CHSesame2 || device is CHSesame5) ? device.mechStatus.map { Int($0.position) } ?? NSNull() : NSNull(),
                "batteryPercentage": connected ? batteries[id].map { $0 as Any } ?? NSNull() : NSNull(),
                "settings": LockSettings.snapshot(device),
                "peripheral": peripheralSettings.snapshot(device)
            ]
            if let hub = device as? CHWifiModule2 { row["hub"] = hubSettings.snapshot(id, hub) }
            if let bot2 = device as? CHSesameBot2 {
                row["scriptIndex"] = Int(bot2.scripts.curIdx)
                row["scripts"] = bot2.scripts.events.enumerated().map { index, script in
                    ["id": index, "name": String(decoding: script.name, as: UTF8.self)]
                }
            }
            return row
        }
        publish?(rows)
    }

    func drop(_ id: String) {
        let id = id.uppercased()
        peripheralSettings.forget(id)
        hubSettings.forget(id)
        appliedKeys[id] = nil
        order.removeAll { $0 == id }
        AutoUnlock.shared.clear(id)
        if let device = devices.removeValue(forKey: id) {
            detach(device)
            device.dropKey { _ in }
        } else if let uuid = UUID(uuidString: id) {
            KeyStore.shared.delete(deviceId: uuid)
        }
        cloudRows.removeAll { ($0["deviceUUID"] as? String)?.uppercased() == id }
        SesameShortcuts.updateAppShortcutParameters()
        WatchKeySync.shared.push()
        snapshot()
    }

    func command(_ json: [String: Any], reply: @escaping (Bool, String?) -> Void) {
        guard let device = devices[(json["deviceUUID"] as? String ?? "").uppercased()] else {
            return reply(false, "Bluetooth device unavailable")
        }
        guard device.deviceStatus.loginStatus == .logined else {
            return reply(false, "Bluetooth disconnected")
        }
        let result: CHResult<CHEmpty> = { outcome in
            DispatchQueue.main.async {
                if case .success = outcome { reply(true, nil) } else { reply(false, "Bluetooth command failed") }
            }
        }
        if json["action"] as? String == "home.scripts" {
            guard let bot2 = device as? CHSesameBot2 else { return reply(false, "Unsupported device") }
            bot2.getScriptNameList { outcome in
                DispatchQueue.main.async {
                    self.snapshot()
                    if case .success = outcome { reply(true, nil) } else { reply(false, "Unable to read scripts") }
                }
            }
            return
        }
        let operation = json["operation"] as? String
        switch device {
        case let lock as CHSesame5:
            switch operation {
            case "lock": lock.lock(historytag: os3HistoryTag(), result: result)
            case "unlock": lock.unlock(historytag: os3HistoryTag(), result: result)
            default: lock.toggle(historytag: os3HistoryTag(), result: result)
            }
        case let lock as CHSesame2:
            switch operation {
            case "lock": lock.lock(historytag: os2History, result: result)
            case "unlock": lock.unlock(historytag: os2History, result: result)
            default: lock.toggle(historytag: os2History, result: result)
            }
        case let bike as CHSesameBike:
            bike.unlock(historytag: os2History, result: result)
        case let bike as CHSesameBike2:
            bike.unlock(historytag: os3HistoryTag(), result: result)
        case let bot as CHSesameBot:
            bot.click(historytag: os2History, result: result)
        case let bot as CHSesameBot2:
            let id = device.deviceId.uuidString.uppercased()
            let cloud = cloudRows.first { ($0["deviceUUID"] as? String)?.uppercased() == id }
            let scripts = (cloud?["stateInfo"] as? [String: Any])?["scriptList"] as? [[String: Any]]
            let defaultIndex = scripts?.first { $0["isDefault"] as? Int == 1 }?["actionIndex"] as? Int
            let index = json["scriptIndex"].map { $0 as? Int ?? -1 } ?? defaultIndex ?? Int(bot.scripts.curIdx)
            guard (0...9).contains(index) else { return reply(false, "Invalid script index") }
            bot.click(index: UInt8(index), historytag: os3HistoryTag(), result: result)
        default:
            reply(false, "Unsupported Bluetooth command")
        }
    }
}

extension BleController: CHDeviceStatusAndKeysDelegate, CHBleStatusDelegate, CHRemoteNanoDelegate, CHSesame5Delegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        DispatchQueue.main.async {
            guard self.devices[device.uuid] === device else { return }
            self.hubSettings.statusChanged(device)
            self.peripheralSettings.statusChanged(device)
            if device.loggedIn { AutoUnlock.shared.deviceLoggedIn(device) }
            self.connect(device)
            if let bot2 = device as? CHSesameBot2, status.loginStatus == .logined {
                bot2.getScriptNameList { _ in DispatchQueue.main.async { self.snapshot() } }
            }
            self.snapshot()
        }
    }

    func onMechStatus(device: CHDevice) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onBatteryPercentageChanged(device: CHDevice, percentage: Int) {
        DispatchQueue.main.async {
            self.batteries[device.deviceId.uuidString.uppercased()] = percentage
            self.snapshot()
        }
    }

    func onBleTxPowerReceive(device: CHDevice, txPower: UInt8) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func didScanChange(status: CHScanStatus) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String]) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onRadarReceive(device: CHSesameConnector, payload: Data) {
        guard let device = device as? CHDevice else { return }
        DispatchQueue.main.async { self.peripheralSettings.radarReceived(device, payload) }
    }

    func onSlotFull(device: CHSesameConnector) {
        guard let device = device as? CHDevice else { return }
        DispatchQueue.main.async { self.peripheralSettings.warn(device, "deviceFull") }
    }

    func onSSMSupport(device: CHSesameConnector, isSupport: Bool) {
        guard !isSupport, let device = device as? CHDevice else { return }
        DispatchQueue.main.async { self.peripheralSettings.warn(device, "deviceUnsupported") }
    }

    func onTriggerDelaySecondReceived(device: CHSesameConnector, setting: CHRemoteBaseTriggerSettings) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onSensorDetectIntervalReceive(device: CHSesame5, intervalMs: Int16) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onLockUnlockSwitchPointReceive(device: CHSesame5, point: Int16) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        DispatchQueue.main.async { self.snapshot() }
    }

    func onScanWifiSID(device: CHWifiModule2, ssid: CHSSID) {
        DispatchQueue.main.async { self.hubSettings.wifiFound(device, ssid: ssid.name, rssi: Int(ssid.rssi)) }
    }

    func onWifiScanFinished(device: CHWifiModule2) {
        DispatchQueue.main.async { self.hubSettings.wifiScanFinished(device) }
    }

    func onOTAProgress(device: CHWifiModule2, percent: UInt8) {
        DispatchQueue.main.async { self.hubSettings.otaProgress(device, percent: Int(percent)) }
    }
}
