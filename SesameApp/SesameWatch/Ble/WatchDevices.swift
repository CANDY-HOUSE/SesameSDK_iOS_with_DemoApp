import Combine
import Foundation
import Network
import SesameGateway
import SesameSDK

/// Bluetooth on the Watch. Only the selected device connects while the app is in front, and only the Siri target while an
/// intent runs; everything else stays disconnected so the iPhone and other users can reach the locks.
@MainActor
final class WatchDevices: NSObject, ObservableObject {
    static let shared = WatchDevices()

    @Published private(set) var list: [WatchStore.Device] = []
    @Published private(set) var selectedId: String?
    private var devices: [String: CHDevice] = [:]
    /// Percentages the server returned for voltages read over Bluetooth.
    private var batteries: [String: Int] = [:]
    private var started = false
    private var active = false
    private var intentTargets: [String: Int] = [:]
    private let defaults = UserDefaults.standard
    private let selectedKey = "watchSelectedUUID"

    /// Also called by intents, which may run before the app's scene.
    func start() {
        guard !started else { return }
        started = true
        CHBleSupport.initialize(host: WatchBleHost(), keys: KeyStore.shared, gatewayTenantId: "")
        selectedId = defaults.string(forKey: selectedKey)
        reload()
    }

    /// Follows `WatchStore` after a new context from the iPhone.
    func reload() {
        let stored = WatchStore.devices()
        let ids = Set(stored.map(\.id))
        for (id, device) in devices where !ids.contains(id) {
            device.multicastDelegate.removeDelegate(self)
            device.dropKey { _ in }
            devices[id] = nil
            batteries[id] = nil
        }
        for item in stored {
            guard let key = KeyStore.shared.key(item.id), let device = CHBluetoothCenter.shared.restoreDevice(key) else { continue }
            if !device.multicastDelegate.containsDelegate(self) { device.multicastDelegate.addDelegate(self) }
            devices[item.id] = device
            connectIfWanted(device)
        }
        list = stored.filter { devices[$0.id] != nil }
        if !list.contains(where: { $0.id == selectedId }) { select(list.first?.id) }
        SesameShortcuts.updateAppShortcutParameters()
    }

    func device(_ id: String) -> CHDevice? {
        devices[id.uppercased()]
    }

    func battery(_ id: String) -> Int? {
        batteries[id.uppercased()]
    }

    func select(_ id: String?) {
        let previous = selectedId
        selectedId = id
        defaults.set(id, forKey: selectedKey)
        if let previous, previous != id, let device = devices[previous], !wanted(previous) { device.disconnect { _ in } }
        if let id, let device = devices[id] { connectIfWanted(device) }
    }

    func resume() {
        active = true
        CHBluetoothCenter.shared.enableScan { _ in }
        devices.values.forEach(connectIfWanted)
    }

    /// Replaces the native app's private screen-off notification: in the background the Watch no longer gets
    /// Bluetooth updates, so it stops scanning and lets the locks go.
    func pause() {
        active = false
        releaseUnwanted()
    }

    /// Siri may run while the app is in the background: scan and log in to the target until the command is done.
    func startIntent(_ id: String) {
        let id = id.uppercased()
        intentTargets[id, default: 0] += 1
        CHBluetoothCenter.shared.enableScan { _ in }
        if let device = devices[id] { connectIfWanted(device) }
    }

    func stopIntent(_ id: String) {
        let id = id.uppercased()
        intentTargets[id] = (intentTargets[id] ?? 1) > 1 ? intentTargets[id]! - 1 : nil
        releaseUnwanted()
    }

    /// Same tags as the iPhone app: OS3 devices record the environment id with the iOS BLE type, OS2 devices the account name.
    func command(_ operation: SesameOperation, _ id: String) async -> Bool {
        guard let device = devices[id.uppercased()], device.deviceStatus.loginStatus == .logined else { return false }
        let os3Tag = Data([0x00, 0x0f]) + WatchStore.historyTag
        let os2Tag = WatchStore.historyName
        return await withCheckedContinuation { continuation in
            let result: CHResult<CHEmpty> = { outcome in
                if case .success = outcome { continuation.resume(returning: true) } else { continuation.resume(returning: false) }
            }
            switch device {
            case let lock as CHSesame5:
                switch operation {
                case .lock: lock.lock(historytag: os3Tag, result: result)
                case .unlock: lock.unlock(historytag: os3Tag, result: result)
                case .toggle: lock.toggle(historytag: os3Tag, result: result)
                }
            case let lock as CHSesame2:
                switch operation {
                case .lock: lock.lock(historytag: os2Tag, result: result)
                case .unlock: lock.unlock(historytag: os2Tag, result: result)
                case .toggle: lock.toggle(historytag: os2Tag, result: result)
                }
            case let bike as CHSesameBike:
                bike.unlock(historytag: os2Tag, result: result)
            case let bike as CHSesameBike2:
                bike.unlock(historytag: os3Tag, result: result)
            case let bot as CHSesameBot:
                bot.click(historytag: os2Tag, result: result)
            case let bot as CHSesameBot2:
                bot.click(index: nil, historytag: os3Tag, result: result)
            default:
                continuation.resume(returning: false)
            }
        }
    }

    /// Gateway commands use the iOS Wi-Fi type (UUID4HistoryTagType 17), as on the iPhone.
    func gatewayHistoryTag() -> Data {
        Data([0x00, 0x11]) + WatchStore.historyTag
    }

    private func wanted(_ id: String) -> Bool {
        (active && id == selectedId) || intentTargets[id] != nil
    }

    private func connectIfWanted(_ device: CHDevice) {
        guard let id = device.deviceId?.uuidString.uppercased(), wanted(id), device.deviceStatus == .receivedBle() else { return }
        device.connect { _ in }
    }

    private func releaseUnwanted() {
        for (id, device) in devices where !wanted(id) {
            device.disconnect { _ in }
        }
        if !active && intentTargets.isEmpty { CHBluetoothCenter.shared.disableScan { _ in } }
    }

    private func statusChanged(_ device: CHDevice) {
        guard let id = device.deviceId?.uuidString.uppercased(), devices[id] === device else { return }
        connectIfWanted(device)
        objectWillChange.send()
    }
}

extension WatchDevices: CHDeviceStatusAndKeysDelegate {
    nonisolated func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        Task { @MainActor in self.statusChanged(device) }
    }

    nonisolated func onMechStatus(device: CHDevice) {
        Task { @MainActor in self.statusChanged(device) }
    }

    nonisolated func onBatteryPercentageChanged(device: CHDevice, percentage: Int) {
        Task { @MainActor in
            guard let id = device.deviceId?.uuidString.uppercased(), self.devices[id] === device else { return }
            self.batteries[id] = percentage
            self.objectWillChange.send()
        }
    }
}

/// The Watch has no Biz, so it talks to the native app's REST endpoints like the old Watch app did: restricted (guest)
/// keys are signed by the server, and history and battery voltage read over Bluetooth are uploaded. Firmware versions are not.
/// Without network or gateway configuration the SDK keeps history on the device for the iPhone to upload later.
private final class WatchBleHost: CHBleHost {
    private let monitor = NWPathMonitor()
    private var networkAvailable = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.networkAvailable = path.status == .satisfied
        }
        monitor.start(queue: DispatchQueue(label: "WatchBleHost.network"))
    }

    func isNetworkAvailable() -> Bool {
        networkAvailable && (try? WatchGateway.configure()) != nil
    }

    /// As on the iPhone: a device with a gateway has its history uploaded by the gateway.
    func shouldUploadHistory(deviceId: UUID) -> Bool {
        !WatchStore.devices().contains { $0.id == deviceId.uuidString.uppercased() && $0.gateway }
    }

    func signGuestKey(deviceId: UUID, token: String, secretKey: String, result: @escaping CHResult<String>) {
        Task {
            do {
                result(.success(CHResultStateNetworks(input: try await SesameGateway.sign(deviceId: deviceId, token: token, guestKeyId: secretKey))))
            } catch {
                result(.failure(error))
            }
        }
    }

    func postHistory(deviceId: UUID, historyHex: String, os3: Bool, result: @escaping CHResult<CHEmpty>) {
        Task {
            do {
                try await SesameGateway.postHistory(deviceId: deviceId, historyHex: historyHex, os3: os3)
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            } catch {
                result(.failure(error))
            }
        }
    }

    func postFirmwareVersion(deviceId: UUID, versionTag: String, result: @escaping CHResult<CHEmpty>) {
        result(.failure(HostError.unsupported))
    }

    func postBatteryData(deviceId: UUID, payload: String, result: @escaping CHResult<Int>) {
        Task {
            do {
                result(.success(CHResultStateNetworks(input: try await SesameGateway.battery(deviceId: deviceId, payload: payload))))
            } catch {
                result(.failure(error))
            }
        }
    }

    func registerOs2(deviceId: UUID, appKey: String, nonce: String, registrationKey: String, productType: String, result: @escaping CHResult<CHRegistrationResult>) {
        result(.failure(HostError.unsupported))
    }

    func registerOs3(deviceId: UUID, productType: Int, publicKey: String, result: @escaping CHResult<CHEmpty>) {
        result(.failure(HostError.unsupported))
    }

    enum HostError: Error {
        case unsupported
    }
}
