import Foundation
import SesameSDK

final class BleRegistrationController: NSObject {
    var publish: (([String: Any]) -> Void)?
    var registered: ((CHDevice) -> Void)?
    var removedDevices: Set<String> = []
    private var devices: [String: CHDevice] = [:]
    private var active = false
    private var sessionStartedAt = Date.distantPast
    private var registering: CHDevice?
    private var previousDelegate: CHDeviceStatusDelegate?
    private var complete: ((Bool, String?) -> Void)?
    private var timeout: DispatchWorkItem?
    private var started = false

    private static let connectedStatuses: [CHDeviceStatus] = [
        .bleConnecting(), .waitingGatt(), .bleLogining(), .readyToRegister(), .waitingForAuth(), .registering()
    ]

    private var bluetoothOff: Bool { CHBluetoothCenter.shared.scanning == .bleClose() }

    func start() {
        guard registering == nil else { return }
        let restarting = active
        sessionStartedAt = Date()
        active = true
        CHBluetoothCenter.shared.delegate = self
        if restarting {
            CHBluetoothCenter.shared.disableScan { _ in CHBluetoothCenter.shared.enableScan { _ in } }
        } else {
            CHBluetoothCenter.shared.enableScan { _ in }
        }
        publishDevices()
    }

    func stop() {
        active = false
        if CHBluetoothCenter.shared.delegate === self { CHBluetoothCenter.shared.delegate = nil }
        for device in devices.values where !device.isRegistered && device.deviceStatus.loginStatus != .logined && device !== registering {
            device.disconnect { _ in }
        }
        devices.removeAll()
    }

    func close() {
        stop()
        finish(false, "Registration page closed")
    }

    private func seenThisSession(_ device: CHDevice) -> Bool {
        Self.connectedStatuses.contains(device.deviceStatus) ||
            (CHBluetoothCenter.shared.lastAdvertisedAt(device.deviceId) ?? .distantPast) >= sessionStartedAt
    }

    private func publishDevices() {
        let rows: [[String: Any]] = devices.values
            .sorted { ($0.rssi?.intValue ?? .min) > ($1.rssi?.intValue ?? .min) }
            .map { device in
                [
                    "deviceUUID": device.deviceId.uuidString.uppercased(),
                    "name": device.productModel.deviceModelName(),
                    "rssi": device.rssi ?? NSNull(),
                    "bleState": device.deviceStatus.webBleState,
                    "registered": device.isRegistered
                ]
            }
        publish?(["bluetoothOff": bluetoothOff, "devices": rows])
    }

    func register(_ id: String, reply: @escaping (Bool, String?) -> Void) {
        guard !bluetoothOff else { return reply(false, "Bluetooth disconnected") }
        guard registering == nil else { return reply(false, "Registration in progress") }
        guard let device = devices[id.uppercased()], !device.isRegistered else {
            return reply(false, "Device no longer available; scan again")
        }
        registering = device
        complete = reply
        previousDelegate = device.delegate
        started = false
        device.delegate = self
        let work = DispatchWorkItem { [weak self] in
            self?.finish(false, "Registration timed out; check the device list before retrying")
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: work)
        attempt()
        if !started {
            device.connect { [weak self] result in
                DispatchQueue.main.async {
                    if case .failure = result { self?.finish(false, "Bluetooth connection failed") } else { self?.attempt() }
                }
            }
        }
    }

    private func attempt() {
        guard let device = registering, !started, device.deviceStatus == .readyToRegister() else { return }
        guard !bluetoothOff else { return finish(false, "Bluetooth disconnected") }
        started = true
        device.register { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.registered?(device)
                    (device as? CHSesameLock)?.setHistoryTag(BleController.shared.historyTag()) { _ in }
                    (device as? CHSesame2)?.configureLockPosition(lockTarget: 0, unlockTarget: 90) { _ in }
                    if self.registering === device { self.finish(true, nil) }
                case .failure:
                    if self.registering === device { self.finish(false, "Registration failed") }
                }
            }
        }
    }

    private func finish(_ success: Bool, _ error: String?) {
        timeout?.cancel()
        timeout = nil
        registering?.delegate = previousDelegate
        registering = nil
        previousDelegate = nil
        let callback = complete
        complete = nil
        callback?(success, error)
    }
}

extension BleRegistrationController: CHBleManagerDelegate, CHDeviceStatusDelegate {
    func didDiscoverUnRegisteredCHDevices(_ found: [CHDevice]) {
        DispatchQueue.main.async {
            guard self.active else { return }
            let removed = self.removedDevices.compactMap { UUID(uuidString: $0) }
                .compactMap(CHBluetoothCenter.shared.scannedDevice).filter(\.isRegistered)
            self.devices.removeAll()
            for device in found + removed where device.deviceId != nil && device.rssi != nil &&
                device.productModel != .sesameFace3 && self.seenThisSession(device) {
                self.devices[device.deviceId.uuidString.uppercased()] = device
            }
            if self.registering == nil,
               let nearest = self.devices.values.filter({ !$0.isRegistered }).max(by: { ($0.rssi?.intValue ?? .min) < ($1.rssi?.intValue ?? .min) }),
               nearest.deviceStatus == .receivedBle() {
                nearest.connect { _ in }
            }
            self.publishDevices()
        }
    }

    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        DispatchQueue.main.async {
            self.attempt()
            if self.active { self.publishDevices() }
        }
    }
}
