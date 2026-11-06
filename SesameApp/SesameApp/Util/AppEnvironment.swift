import CoreBluetooth
import CoreLocation
import Network
import SesameSDK
import UIKit
import UserNotifications

/// Installation environment reported with push subscriptions, as `[{key: value}]` in a fixed order shared with Android.
enum AppEnvironment {
    @MainActor
    static func collect() async -> [[String: Any]] {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let device = UIDevice.current
        let screen = UIScreen.main
        let monitoring = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let battery = device.batteryLevel < 0 ? -1 : Int((device.batteryLevel * 100).rounded())
        device.isBatteryMonitoringEnabled = monitoring
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let pairs: [(String, Any)] = [
            ("displayName", Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Sesame"),
            ("version", AppConfig.versionName),
            ("build", AppConfig.versionCode),
            ("language", Locale.preferredLanguages.first ?? ""),
            ("region", Locale.current.region?.identifier ?? ""),
            ("bundleId", Bundle.main.bundleIdentifier ?? ""),
            ("systemName", device.systemName),
            ("systemVersion", device.systemVersion),
            ("model", AppConfig.model),
            ("deviceType", device.userInterfaceIdiom == .pad ? "pad" : "phone"),
            ("screenWidth", Int(screen.bounds.width)),
            ("screenHeight", Int(screen.bounds.height)),
            ("screenScale", screen.scale),
            ("timeZone", TimeZone.current.identifier),
            ("batteryLevel", battery),
            ("notification", notification(settings.authorizationStatus)),
            ("bluetooth", bluetooth()),
            ("location", location()),
            ("network", BleBackend.shared.networkType),
            ("collectedAt", formatter.string(from: Date()))
        ]
        return pairs.map { [$0.0: $0.1] }
    }

    private static func notification(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    private static func bluetooth() -> String {
        if CBCentralManager.authorization == .denied || CBCentralManager.authorization == .restricted { return "unauthorized" }
        switch CHBluetoothCenter.shared.centralManager.state {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        default: return "unknown"
        }
    }

    private static func location() -> String {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways: return "always"
        case .authorizedWhenInUse: return "whenInUse"
        case .notDetermined: return "notDetermined"
        default: return "denied"
        }
    }
}
