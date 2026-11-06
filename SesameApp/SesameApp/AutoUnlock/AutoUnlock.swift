import CoreLocation
import Foundation
import SesameSDK
import UserNotifications

/// Stores Biz's auto-unlock choices and monitors home regions: leaving arms a lock, the next BLE login unlocks it.
/// Keys match the Android preference names so both hosts describe the same settings.
final class AutoUnlock: NSObject, CLLocationManagerDelegate {
    static let shared = AutoUnlock()

    var permissionChanged: (() -> Void)?
    private(set) var notificationsEnabled = false
    private let manager = CLLocationManager()
    private let defaults = UserDefaults.standard
    private var permissionRequested = false

    func start() {
        manager.delegate = self
        refreshNotificationSetting()
        sync()
    }

    func refreshNotificationSetting() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let enabled = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            DispatchQueue.main.async { self.notificationsEnabled = enabled }
        }
    }

    private var permission: String {
        switch manager.authorizationStatus {
        case .authorizedAlways: return "granted"
        case .authorizedWhenInUse: return "foreground"
        default: return "none"
        }
    }

    func enabled(_ id: String) -> Bool { defaults.bool(forKey: "nohand" + key(id)) }
    func armed(_ id: String) -> Bool { defaults.bool(forKey: "nohandg" + key(id)) }
    private func key(_ id: String) -> String { id.lowercased() }

    func snapshot(_ id: String) -> [String: Any] {
        let key = key(id)
        let radius = defaults.object(forKey: "getNOHandRadius" + key) as? Double ?? 150
        return [
            "nfc": "",
            "widget": false,
            "autoUnlock": enabled(id),
            "latitude": defaults.double(forKey: "getNOHandLeft" + key),
            "longitude": defaults.double(forKey: "getNOHandRight" + key),
            "radius": min(max(radius, 20), 500),
            "notificationsEnabled": notificationsEnabled
        ]
    }

    func handle(_ json: [String: Any], openSettings: () -> Void) throws -> [String: Any] {
        let id = json["deviceUUID"] as? String ?? ""
        try require(BleController.shared.device(id) != nil)
        let key = key(id)
        switch json["operation"] as? String {
        case "get":
            break
        case "region":
            if let value = json["latitude"] as? Double {
                try require(value.isFinite && (-90...90).contains(value))
                defaults.set(value, forKey: "getNOHandLeft" + key)
            }
            if let value = json["longitude"] as? Double {
                try require(value.isFinite && (-180...180).contains(value))
                defaults.set(value, forKey: "getNOHandRight" + key)
            }
            if let value = json["radius"] as? Double {
                try require(value.isFinite && (20...500).contains(value))
                defaults.set(value, forKey: "getNOHandRadius" + key)
            }
            sync()
        case "enable":
            if json["value"] as? Bool != true {
                defaults.set(false, forKey: "nohand" + key)
                defaults.set(false, forKey: "nohandg" + key)
            } else if manager.authorizationStatus == .authorizedAlways {
                defaults.set(true, forKey: "nohand" + key)
            }
            sync()
        case "requestPermission":
            permissionRequested = true
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestAlwaysAuthorization()
            }
        case "openSettings":
            openSettings()
        default:
            throw BleError.unsupported
        }
        var data = snapshot(id)
        data["permission"] = permission
        return data
    }

    func clear(_ id: String) {
        let key = key(id)
        ["nohand", "nohandg", "getNOHandLeft", "getNOHandRight", "getNOHandRadius"].forEach { defaults.removeObject(forKey: $0 + key) }
        sync()
    }

    func rememberLegacy(_ id: String, enabled: Bool, latitude: Double, longitude: Double, radius: Double) {
        let key = key(id)
        guard defaults.object(forKey: "nohand" + key) == nil else { return }
        defaults.set(enabled, forKey: "nohand" + key)
        defaults.set(latitude, forKey: "getNOHandLeft" + key)
        defaults.set(longitude, forKey: "getNOHandRight" + key)
        if radius > 0 { defaults.set(min(max(radius, 20), 500), forKey: "getNOHandRadius" + key) }
    }

    /// Regions follow the saved keys, so monitoring works before Biz has loaded.
    func sync() {
        let wanted: [CLCircularRegion] = manager.authorizationStatus == .authorizedAlways ? KeyStore.shared.all().compactMap { key in
            let id = key.deviceUUID.uuidString.uppercased()
            guard enabled(id) else { return nil }
            let data = snapshot(id)
            let latitude = data["latitude"] as? Double ?? 0
            let longitude = data["longitude"] as? Double ?? 0
            guard latitude != 0 || longitude != 0 else { return nil }
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                          radius: data["radius"] as? Double ?? 150, identifier: id)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            return region
        } : []
        let wantedIds = Set(wanted.map(\.identifier))
        for region in manager.monitoredRegions where !wantedIds.contains(region.identifier) {
            manager.stopMonitoring(for: region)
        }
        for region in wanted.prefix(20) {
            let existing = manager.monitoredRegions.first { $0.identifier == region.identifier } as? CLCircularRegion
            if existing?.center.latitude != region.center.latitude || existing?.center.longitude != region.center.longitude || existing?.radius != region.radius {
                manager.startMonitoring(for: region)
                manager.requestState(for: region)
            }
        }
        if anyArmed { BleController.shared.startBackground() } else { BleController.shared.stopBackground() }
    }

    private var anyArmed: Bool {
        KeyStore.shared.all().contains { enabled($0.deviceUUID.uuidString) && armed($0.deviceUUID.uuidString) }
    }

    func deviceLoggedIn(_ device: CHDevice) {
        let id = device.uuid
        guard enabled(id), armed(id), device.rssi != nil else { return }
        defaults.set(false, forKey: "nohandg" + key(id))
        if device.deviceStatus != .unlocked() {
            BleController.shared.command(["deviceUUID": id, "operation": "unlock"]) { _, _ in }
        }
        if !anyArmed { BleController.shared.stopBackground() }
    }

    private func leave(_ id: String) {
        guard enabled(id) else { return }
        defaults.set(true, forKey: "nohandg" + key(id))
        BleController.shared.restoreSaved()
        BleController.shared.startBackground()
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        leave(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if armed(region.identifier) {
            BleController.shared.restoreSaved()
            BleController.shared.startBackground()
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard state == .outside else { return }
        leave(region.identifier)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if permissionRequested, manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        if manager.authorizationStatus != .notDetermined {
            permissionRequested = false
            permissionChanged?()
        }
        sync()
    }
}
