//
//  AppEnvironment.swift
//  SesameUI
//
//  采集 App 运行环境信息，作为 metadata 上报后端。
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import UserNotifications
import SesameSDK

/// 采集尽可能完整的 App 环境信息，拍平为一层 `key=value` 字符串数组上报。
enum AppEnvironment {

    /// 异步采集全部环境信息（推送授权状态需异步查询）。
    /// - Parameter completion: 在主线程回调有序数组，每项是单键对象 `[{"key": value}, ...]`。
    static func collect(completion: @escaping ([[String: Any]]) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // 有序键值对；数组顺序即字段顺序（字典无序，故不用字典）
            var pairs: [(String, Any)] = []
            pairs += appInfo()
            pairs += deviceInfo()
            pairs += permissionInfo(notification: settings)
            let ms = String(Int64(Date().timeIntervalSince1970 * 1000))
            pairs.append(("collectedAt", ms.localizedTime() ?? ms))
            let env = pairs.map { [$0.0: $0.1] }
            DispatchQueue.main.async { completion(env) }
        }
    }

    // MARK: - App

    private static func appInfo() -> [(String, Any)] {
        let info = Bundle.main.infoDictionary ?? [:]
        return [
            ("displayName", info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? ""),
            ("version", info["CFBundleShortVersionString"] as? String ?? ""),
            ("build", info["CFBundleVersion"] as? String ?? ""),
            ("language", Locale.preferredLanguages.first ?? ""),
            ("region", Locale.current.regionCode ?? ""),
            ("bundleId", Bundle.main.bundleIdentifier ?? "")
        ]
    }

    // MARK: - Device / System

    private static func deviceInfo() -> [(String, Any)] {
        let device = UIDevice.current
        let screen = UIScreen.main
        let wasBatteryMonitoringEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true // 读取电量前需开启监控
        let battery = batteryLevelPercent(device.batteryLevel)
        device.isBatteryMonitoringEnabled = wasBatteryMonitoringEnabled
        return [
            ("systemName", device.systemName),
            ("systemVersion", device.systemVersion),
            ("model", hardwareModel()),
            ("deviceType", device.userInterfaceIdiom == .pad ? "pad" : "phone"),
            ("screenWidth", Int(screen.bounds.width)),
            ("screenHeight", Int(screen.bounds.height)),
            ("screenScale", screen.scale),
            ("timeZone", TimeZone.current.identifier),
            ("batteryLevel", battery)
        ]
    }

    /// 电量百分比 0–100；监控未就绪 / 未知返回 -1。
    private static func batteryLevelPercent(_ level: Float) -> Int {
        level < 0 ? -1 : Int((level * 100).rounded())
    }

    /// 硬件机型标识，如 "iPhone15,3"。
    private static func hardwareModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier += String(UnicodeScalar(UInt8(value)))
        }
    }

    // MARK: - Permissions / Capabilities

    private static func permissionInfo(notification settings: UNNotificationSettings) -> [(String, Any)] {
        return [
            ("notification", notificationAuthString(settings.authorizationStatus)),
            ("bluetooth", bluetoothAuthString()),
            ("location", locationAuthString()),
            ("network", networkTypeString())
        ]
    }

    private static func notificationAuthString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown"
        }
    }

    /// 蓝牙真实状态（电源开关 + 授权），复用常驻 central manager 的 state。
    /// 注意：CBManager.authorization 只反映权限，设置里关蓝牙仍是 authorized，这里用 state 才准。
    private static func bluetoothAuthString() -> String {
        switch CHBluetoothCenter.shared.centralManager.state {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        case .resetting: return "resetting"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }

    private static func locationAuthString() -> String {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = CLLocationManager().authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "always"
        case .authorizedWhenInUse: return "whenInUse"
        @unknown default: return "unknown"
        }
    }

    private static func networkTypeString() -> String {
        switch NetworkReachabilityHelper.shared.currentState {
        case .reachable(.cellular): return "cellular"
        case .reachable(.ethernetOrWiFi): return "wifi"
        case .notReachable: return "none"
        case .unknown: return "unknown"
        }
    }

}
