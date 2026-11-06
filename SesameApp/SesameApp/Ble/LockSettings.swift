import Foundation
import SesameSDK

enum LockSettings {
    private static let readTimeout: TimeInterval = 8

    static func snapshot(_ device: CHDevice) -> [String: Any] {
        var data: [String: Any] = [
            "productType": Int(device.productModel.rawValue),
            "deviceModel": device.productModel.deviceModel(),
            "deviceModelName": device.productModel.deviceModelName()
        ]
        guard device.loggedIn else { return data }
        if device.bleTxPower != CHDeviceUnsetBleTxPowerValue { data["bleTxPower"] = Int(Int8(bitPattern: device.bleTxPower)) }
        if let lock = device as? CHSesame5, let setting = lock.mechSetting {
            data["lockPosition"] = Int(setting.lockPosition)
            data["unlockPosition"] = Int(setting.unlockPosition)
            data["autoLockSeconds"] = Int(setting.autoLockSecond)
        } else if let lock = device as? CHSesame2, let setting = lock.mechSetting {
            data["lockPosition"] = Int(setting.lockPosition)
            data["unlockPosition"] = Int(setting.unlockPosition)
        }
        if let lock = device as? CHSesame5 {
            if let ops = lock.opsSetting { data["sensorLockSeconds"] = Int(ops.opsLockSecond) }
            data["magnet"] = true
            if lock.hasLockUnlockSwitchPointSetting { data["switchPoint"] = Int(lock.lockUnlockSwitchPoint) }
            if lock.sensorDetectIntervalMs != CHDeviceUnsetSensorDetectInterval { data["sensorInterval"] = Int(lock.sensorDetectIntervalMs) }
        }
        data["position"] = device.mechStatus.map { Int($0.position) as Any } ?? NSNull()
        return data
    }

    @MainActor
    static func handle(_ ble: BleController, _ json: [String: Any]) async throws -> [String: Any] {
        guard let device = ble.device(json["deviceUUID"] as? String ?? "") else { throw BleError.unavailable }
        try require(device.loggedIn)
        let operation = json["operation"] as? String ?? ""
        try require(device is CHSesame2 || device is CHSesame5 || (device is CHSesameLock && ["txPower", "version"].contains(operation)))
        switch operation {
        case "txPower":
            let value = json["value"] as? Int ?? .min
            try require(device.bleTxPower != CHDeviceUnsetBleTxPowerValue && (-4...20).contains(value))
            let _: CHEmpty = try await bleResult(timeout: readTimeout) { device.setBleTxPower(txPower: Int8(value).txPowerByte, result: $0) }
        case "read":
            var data = snapshot(device)
            if let lock = device as? CHSesame2 {
                data["autoLockSeconds"] = try await bleResult(timeout: readTimeout) { lock.getAutolockSetting(result: $0) }
            }
            return data
        case "version":
            let version: String = try await bleResult(timeout: readTimeout) { device.getVersionTag(result: $0) }
            return ["version": version]
        case "lockPosition", "unlockPosition":
            guard let position = device.mechStatus?.position else { throw BleError.unavailable }
            if let lock = device as? CHSesame5, let setting = lock.mechSetting {
                let _: CHEmpty = try await bleResult(timeout: readTimeout) {
                    lock.configureLockPosition(lockTarget: operation == "lockPosition" ? position : setting.lockPosition,
                                               unlockTarget: operation == "unlockPosition" ? position : setting.unlockPosition, result: $0)
                }
            } else if let lock = device as? CHSesame2, let setting = lock.mechSetting {
                let _: CHEmpty = try await bleResult(timeout: readTimeout) {
                    lock.configureLockPosition(historytag: ble.os2HistoryTag(),
                                               lockTarget: operation == "lockPosition" ? position : setting.lockPosition,
                                               unlockTarget: operation == "unlockPosition" ? position : setting.unlockPosition, result: $0)
                }
            } else {
                throw BleError.unavailable
            }
        case "autoLock":
            let seconds = json["value"] as? Int ?? -1
            try require([0, 3, 5, 7, 10, 15, 30, 60, 120, 180, 240, 300, 600, 900, 1800, 3600].contains(seconds))
            if let lock = device as? CHSesame5 {
                let _: Int = try await bleResult(timeout: readTimeout) { lock.autolock(historytag: ble.historyTag(), delay: seconds, result: $0) }
            } else if let lock = device as? CHSesame2 {
                let _: Int = try await bleResult(timeout: readTimeout) { lock.enableAutolock(historytag: ble.os2HistoryTag(), delay: seconds, result: $0) }
            }
            ble.snapshot()
            var data = snapshot(device)
            data["autoLockSeconds"] = seconds
            return data
        case "sensorLock":
            guard let lock = device as? CHSesame5 else { throw BleError.unsupported }
            let seconds = json["value"] as? Int ?? -1
            try require([65535, 0, 1, 2, 3, 4, 5, 7, 10, 15, 30, 60, 120, 180, 240, 300, 600, 900, 1800, 3600].contains(seconds))
            let _: Int = try await bleResult(timeout: readTimeout) { lock.opSensorControl(delay: seconds, result: $0) }
            ble.snapshot()
            var data = snapshot(device)
            data["sensorLockSeconds"] = seconds
            return data
        case "magnet":
            guard let lock = device as? CHSesame5 else { throw BleError.unsupported }
            let _: CHEmpty = try await bleResult(timeout: readTimeout) { lock.magnet(result: $0) }
        case "switchPoint":
            guard let lock = device as? CHSesame5, lock.hasLockUnlockSwitchPointSetting, let position = device.mechStatus?.position else {
                throw BleError.unsupported
            }
            let _: CHEmpty = try await bleResult(timeout: readTimeout) { lock.setLockUnlockSwitchPoint(point: position, result: $0) }
        case "slidingMode":
            guard let lock = device as? CHSesame5 else { throw BleError.unsupported }
            let target: CHProductModel
            switch device.productModel {
            case .sesame6Pro: target = .sesame6ProSlidingDoor
            case .sesame6ProSlidingDoor: target = .sesame6Pro
            default: throw BleError.unsupported
            }
            let _: CHEmpty = try await bleResult(timeout: readTimeout) { lock.sendAdvProductTypeCommand(data: Data([UInt8(truncatingIfNeeded: target.rawValue)]), result: $0) }
            ble.saveModel(device, target)
        case "sensorInterval":
            guard let lock = device as? CHSesame5, lock.sensorDetectIntervalMs != CHDeviceUnsetSensorDetectInterval else { throw BleError.unsupported }
            let interval = json["value"] as? Int ?? -1
            try require(interval == 0 || ((50...1000).contains(interval) && interval % 50 == 0))
            let _: CHEmpty = try await bleResult(timeout: readTimeout) { lock.setSensorDetectInterval(intervalMs: Int16(interval), result: $0) }
        default:
            throw BleError.unsupported
        }
        ble.snapshot()
        return snapshot(device)
    }
}
