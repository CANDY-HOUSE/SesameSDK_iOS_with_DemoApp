import Foundation
import SesameSDK

/// Hub3/WM2 BLE session, Wi-Fi scan and OTA transport; the network setup flow lives in Biz.
final class HubSettings {
    private final class WifiScan {
        var results: [(ssid: String, rssi: Int)] = []
        let startedAt = Date()
        var scanning = true
        var failed = false
        var commandPending = true
        var endReceived = false
        var timeout: DispatchWorkItem?
    }

    private final class Ota {
        var progress = 0
        var receivedProgress = false
        var timeout: DispatchWorkItem?
    }

    private unowned let ble: BleController
    private var sessions: [String: String] = [:]
    private var wifi: [String: WifiScan] = [:]
    private var disconnects: [String: DispatchWorkItem] = [:]
    private var ota: [String: Ota] = [:]

    init(ble: BleController) {
        self.ble = ble
    }

    func watching(_ id: String) -> Bool { sessions[id] != nil }

    func statusChanged(_ device: CHDevice) {
        if !device.loggedIn { clearScan(device.uuid) }
    }

    func wifiFound(_ device: CHWifiModule2, ssid: String, rssi: Int) {
        guard let scan = wifi[device.uuid], scan.scanning else { return }
        if let index = scan.results.firstIndex(where: { $0.ssid == ssid }) {
            guard scan.results[index].rssi < rssi else { return }
            scan.results[index].rssi = rssi
        } else {
            scan.results.append((ssid, rssi))
        }
        ble.snapshot()
    }

    func wifiScanFinished(_ device: CHWifiModule2) {
        guard let scan = wifi[device.uuid], scan.scanning else { return }
        scan.endReceived = true
        if !scan.commandPending { finishScan(device.uuid, scan, failed: false) }
    }

    func otaProgress(_ device: CHWifiModule2, percent: Int) {
        let id = device.uuid
        guard (0...100).contains(percent) else { return }
        let state: Ota
        if let existing = ota[id] {
            state = existing
        } else if percent < 100 {
            state = Ota()
            ota[id] = state
        } else {
            return
        }
        state.progress = percent
        state.receivedProgress = true
        armOtaTimeout(id, state)
        ble.snapshot()
    }

    func forget(_ id: String) {
        clearSession(id)
        ota.removeValue(forKey: id)?.timeout?.cancel()
    }

    /// A grace connection is only useful while the app stays in the foreground.
    func endGrace() {
        for id in disconnects.keys {
            clearSession(id)
            ble.device(id)?.disconnect { _ in }
        }
    }

    func close() {
        Set(sessions.keys).union(disconnects.keys).union(wifi.keys).forEach(clearSession)
        ota.values.forEach { $0.timeout?.cancel() }
        ota.removeAll()
    }

    func snapshot(_ id: String, _ device: CHWifiModule2) -> [String: Any] {
        var hub: [String: Any] = [:]
        if device.loggedIn {
            if let setting = device.mechSetting {
                hub["wifiSsid"] = setting.wifiSSID ?? NSNull()
                hub["wifiPwd"] = setting.wifiPassword ?? NSNull()
            }
            if let network = device.mechStatus as? CHWifiModule2NetworkStatus {
                hub["network"] = [
                    "isAPWork": network.isAPWork == true,
                    "isNetwork": network.isNetwork == true,
                    "isIoTWork": network.isIoTWork == true,
                    "isBindingAPWork": network.isBindingAPWork,
                    "isConnectingNetwork": network.isConnectingNetwork,
                    "isConnectingIoT": network.isConnectingIoT
                ]
            }
        }
        if let scan = wifi[id] {
            hub["wifiScanning"] = scan.scanning
            hub["wifiScanFailed"] = scan.failed
            hub["wifiScan"] = scan.results.map { ["ssid": $0.ssid, "rssi": $0.rssi] }
        }
        if let state = ota[id] { hub["otaProgress"] = state.progress }
        return hub
    }

    private func clearScan(_ id: String) {
        wifi.removeValue(forKey: id)?.timeout?.cancel()
    }

    private func clearSession(_ id: String) {
        disconnects.removeValue(forKey: id)?.cancel()
        sessions[id] = nil
        clearScan(id)
    }

    private func finishScan(_ id: String, _ scan: WifiScan, failed: Bool) {
        guard wifi[id] === scan, scan.scanning else { return }
        scan.scanning = false
        scan.failed = failed
        scan.timeout?.cancel()
        scan.timeout = nil
        ble.snapshot()
    }

    private func scanWifi(_ id: String, _ hub: CHWifiModule2, refresh: Bool) throws {
        try require(sessions[id] != nil && hub.loggedIn)
        if let state = ota[id], (0...99).contains(state.progress) { return }
        if let previous = wifi[id], previous.scanning || previous.commandPending ||
            (!refresh && !previous.failed && Date().timeIntervalSince(previous.startedAt) < 30) {
            return
        }
        let scan = WifiScan()
        wifi[id] = scan
        ble.snapshot()
        // Older firmware may not publish an end marker; never start a second scan meanwhile.
        let timeout = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.finishScan(id, scan, failed: scan.results.isEmpty || scan.commandPending)
            if scan.commandPending { hub.disconnect { _ in } }
        }
        scan.timeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
        hub.scanWifiSSID { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.wifi[id] === scan else { return }
                scan.commandPending = false
                if case .failure = result {
                    self.finishScan(id, scan, failed: true)
                } else if scan.endReceived {
                    self.finishScan(id, scan, failed: false)
                }
            }
        }
    }

    private func armOtaTimeout(_ id: String, _ state: Ota) {
        state.timeout?.cancel()
        state.timeout = nil
        guard (0...99).contains(state.progress) else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.ota[id] === state else { return }
            state.progress = -7
            self.ble.snapshot()
        }
        state.timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 180, execute: work)
    }

    @MainActor
    func handle(_ json: [String: Any]) async throws -> [String: Any] {
        let id = (json["deviceUUID"] as? String ?? "").uppercased()
        guard let hub = ble.device(id) as? CHWifiModule2 else { throw BleError.unsupported }
        let operation = json["operation"] as? String ?? ""
        let timeout: TimeInterval = operation == "connectWifi" ? 25 : 8
        switch operation {
        case "watch":
            disconnects.removeValue(forKey: id)?.cancel()
            sessions[id] = json["session"] as? String ?? ""
            ble.connect(hub)
        case "unwatch":
            guard sessions[id] == json["session"] as? String else { break }
            sessions[id] = nil
            disconnects.removeValue(forKey: id)?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.clearSession(id)
                hub.disconnect { _ in }
            }
            disconnects[id] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (ble.foreground ? 10 : 0), execute: work)
        case "scan":
            try scanWifi(id, hub, refresh: json["refresh"] as? Bool ?? false)
        case "ssid":
            try require(hub.loggedIn)
            let _: CHEmpty = try await bleResult(timeout: timeout) { hub.setWifiSSID(json["ssid"] as? String ?? "", result: $0) }
        case "password":
            try require(hub.loggedIn)
            let _: CHEmpty = try await bleResult(timeout: timeout) { hub.setWifiPassword(json["password"] as? String ?? "", result: $0) }
        case "connectWifi":
            try require(hub.productModel == .wifiModule2 && hub.loggedIn)
            let _: CHEmpty = try await bleResult(timeout: timeout) { hub.connectWifi(result: $0) }
        case "firmware":
            try require(hub is CHHub3 && hub.loggedIn)
            if let state = ota[id], (0...99).contains(state.progress) { break }
            // Wi-Fi scanning must not compete with OTA or disconnect it on a scan timeout.
            clearScan(id)
            let state = Ota()
            ota[id] = state
            armOtaTimeout(id, state)
            // A reboot can drop the command reply while the Hub keeps downloading; follow OTA notifications.
            hub.updateFirmware { [weak self] result in
                DispatchQueue.main.async {
                    guard let self, self.ota[id] === state, !state.receivedProgress, case .failure = result else { return }
                    state.progress = -7
                    self.armOtaTimeout(id, state)
                    self.ble.snapshot()
                }
            }
        case "firmwareFinish":
            if ota[id]?.progress == 100 { ota.removeValue(forKey: id)?.timeout?.cancel() }
        case "version":
            try require(hub.loggedIn)
            let version: String = try await bleResult(timeout: timeout) { hub.getVersionTag(result: $0) }
            return ["version": version]
        default:
            throw BleError.unsupported
        }
        ble.snapshot()
        return [:]
    }
}
