import Foundation
import SesameSDK

/// Device settings transport only; model policy, labels, radar conversion and cloud sync live in Biz.
final class PeripheralSettings {
    private unowned let ble: BleController
    private var sessions: [String: String] = [:]
    private var departures: [String: DispatchWorkItem] = [:]
    private var setup: Set<String> = []
    private var radar: [String: Int] = [:]
    private var bindingWarnings: [String: [String: Any]] = [:]
    private var warningRevision = 0
    private var closing: [String: Task<Void, Never>] = [:]
    private var credentials: [String: CredentialSession] = [:]
    private let sleepy: Set<CHProductModel> = [.remoteNano, .openSensor]

    init(ble: BleController) {
        self.ble = ble
    }

    func registered(_ id: String) {
        setup.insert(id.uppercased())
    }

    func statusChanged(_ device: CHDevice) {
        if !device.loggedIn { closeCredentials(device.uuid) }
        if sleepy.contains(device.productModel), !device.loggedIn, device.deviceStatus != .readyToRegister() {
            setup.remove(device.uuid)
        }
    }

    func shouldConnect(_ device: CHDevice) -> Bool {
        sessions[device.uuid] != nil && (!sleepy.contains(device.productModel) || setup.contains(device.uuid))
    }

    func radarReceived(_ device: CHDevice, _ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 5 else { return }
        radar[device.uuid] = (1...4).reduce(0) { $0 | (Int(bytes[$1]) << (($1 - 1) * 8)) }
        ble.snapshot()
    }

    func warn(_ device: CHDevice, _ code: String) {
        warningRevision += 1
        bindingWarnings[device.uuid] = ["code": code, "revision": warningRevision]
        ble.snapshot()
    }

    func snapshot(_ device: CHDevice) -> [String: Any] {
        let id = device.uuid
        var data: [String: Any] = [
            "setup": setup.contains(id),
            "sleeping": sleepy.contains(device.productModel) && !setup.contains(id),
            "capabilities": Self.capabilities(device),
            "bound": Array((device as? CHSesameConnector)?.sesame2Keys.keys ?? [:].keys)
        ]
        if let value = radar[id] { data["radar"] = value }
        if let warning = bindingWarnings[id] { data["bindingWarning"] = warning }
        if let delay = (device as? CHSesameBiometricDevice)?.triggerDelaySetting { data["triggerDelay"] = Int(delay.triggerDelaySecond) }
        if let session = credentials[id] { data["credentials"] = session.snapshot() }
        return data
    }

    static func capabilities(_ device: CHDevice) -> [String] {
        if let biometric = device as? CHSesameBiometricDevice {
            let names: [BiometricCapability: String] = [.card: "card", .fingerPrint: "fingerprint", .passCode: "passcode", .palm: "palm", .face: "face"]
            return BiometricCapability.allCases.filter(biometric.supportedCapabilities.contains).compactMap { names[$0] }
        }
        return device is CHFingerPrintCapable ? ["fingerprint"] : []
    }

    func forget(_ id: String) {
        departures.removeValue(forKey: id)?.cancel()
        sessions[id] = nil
        setup.remove(id)
        closeCredentials(id)
        radar[id] = nil
        bindingWarnings[id] = nil
    }

    private func closeCredentials(_ id: String) {
        if let task = credentials.removeValue(forKey: id)?.close() { closing[id] = task }
    }

    func close() {
        for id in Set(sessions.keys).union(setup).union(credentials.keys) {
            forget(id)
            let device = ble.device(id)
            let pending = closing[id]
            Task { @MainActor in
                await pending?.value
                if self.sessions[id] == nil, !(device is CHSesameLock) { device?.disconnect { _ in } }
            }
        }
    }

    @MainActor
    func handle(_ json: [String: Any]) async throws -> [String: Any] {
        let id = (json["deviceUUID"] as? String ?? "").uppercased()
        guard let device = ble.device(id) else { throw BleError.unavailable }
        let op = json["operation"] as? String ?? ""
        let session = json["session"] as? String ?? ""
        switch op {
        case "watch":
            departures.removeValue(forKey: id)?.cancel()
            sessions[id] = session
            if shouldConnect(device), device.deviceStatus == .receivedBle() { device.connect { _ in } }
        case "unwatch":
            guard sessions[id] == session else { break }
            departures.removeValue(forKey: id)?.cancel()
            // Navigation between the setting and its child pages keeps the registration connection.
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.closeCredentials(id)
                let pending = self.closing[id]
                Task { @MainActor in
                    await pending?.value
                    self.forget(id)
                    if !(device is CHSesameLock) { device.disconnect { _ in } }
                    self.ble.snapshot()
                }
            }
            departures[id] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
        case "credentialsClose":
            if credentials[id]?.token == session { closeCredentials(id) }
        default:
            try require(device.loggedIn && (!sleepy.contains(device.productModel) || setup.contains(id)))
            switch op {
            case "version":
                let version: String = try await bleResult(timeout: 10) { device.getVersionTag(result: $0) }
                return ["version": version]
            case "txPower":
                let value = json["value"] as? Int ?? .min
                try require((-4...20).contains(value) && device.bleTxPower != CHDeviceUnsetBleTxPowerValue)
                let _: CHEmpty = try await bleResult(timeout: 10) { device.setBleTxPower(txPower: Int8(value).txPowerByte, result: $0) }
            case "radar":
                let command = json["command"] as? Int ?? -1
                let value = json["value"] as? Int ?? -1
                try require([0x33, 0x53].contains(command) && (0...512).contains(value))
                guard let connector = device as? CHSesameConnector else { throw BleError.unsupported }
                let payload = Data([UInt8(command)] + (0..<4).map { UInt8(truncatingIfNeeded: value >> (8 * $0)) })
                let _: CHEmpty = try await bleResult(timeout: 10) { connector.setRadarSensitivity(payload: payload, result: $0) }
                radar[id] = value
            case "triggerDelay":
                let value = json["value"] as? Int ?? -1
                guard device.productModel == .remoteNano, [0, 10].contains(value), let nano = device as? CHRemoteNanoCapable else {
                    throw BleError.unsupported
                }
                let _: CHEmpty = try await bleResult(timeout: 10) { nano.setTriggerDelayTime(UInt8(value), result: $0) }
            case "bind", "unbind":
                let target = json["target"] as? String ?? ""
                guard let connector = device as? CHSesameConnector else { throw BleError.unsupported }
                if op == "bind" {
                    guard let lock = ble.device(target) else { throw BleError.unavailable }
                    let _: CHEmpty = try await bleResult(timeout: 10) { connector.insertSesame(lock, result: $0) }
                } else {
                    let _: CHEmpty = try await bleResult(timeout: 10) { connector.removeSesame(tag: target, result: $0) }
                }
            case "credentials":
                let kind = json["kind"] as? String ?? ""
                try require(Self.capabilities(device).contains(kind))
                closeCredentials(id)
                await closing.removeValue(forKey: id)?.value
                let credential = try CredentialSession(device: device, kind: kind, token: session) { [weak self] in self?.ble.snapshot() }
                credentials[id] = credential
                credential.open()
            case "credentialMode", "credentialRename", "credentialDelete", "credentialAdd", "credentialImport":
                guard let credential = credentials[id], credential.token == session else { throw BleError.invalid }
                try await credential.command(op, json)
            default:
                throw BleError.unsupported
            }
        }
        ble.snapshot()
        return snapshot(device)
    }
}
