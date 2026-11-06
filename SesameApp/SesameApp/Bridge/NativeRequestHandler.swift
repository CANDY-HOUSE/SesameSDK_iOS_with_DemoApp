import Foundation
import Network
import SesameSDK
import UIKit

@MainActor
final class NativeRequestHandler {
    struct Host {
        var language: () -> String
        var uiReady: () -> Void
        var snapshot: () -> Void
        var showRoute: (AppRoute) -> Void
        var openWebPage: (URL) -> Void
        var openExternal: (URL) -> Void
        var haptic: (Int) -> Void
        var requestBle: () -> Void
        var startDiscovery: () -> Void
        var stopDiscovery: () -> Void
        var presenter: () -> UIViewController?
    }

    static let capabilities = ["voiceShortcut"]

    private let host: Host
    private let ble: BleController
    private let registration: BleRegistrationController
    private let network = NWPathMonitor()

    init(host: Host, ble: BleController, registration: BleRegistrationController) {
        self.host = host
        self.ble = ble
        self.registration = registration
        network.start(queue: DispatchQueue(label: "NativeRequestHandler.network"))
    }

    func handle(_ json: [String: Any], reply: @escaping WebViewBridge.Reply) async {
        do {
            switch json["action"] as? String ?? "" {
            case "home.uiReady":
                host.uiReady()
                reply(true, nil, nil)

            case "home.ready":
                host.snapshot()
                reply(true, nil, nil)

            case "home.appVersion":
                reply(true, [
                    "versionName": AppConfig.versionName,
                    "versionCode": AppConfig.versionCode,
                    "display": AppConfig.display
                ], nil)

            case "home.session":
                let token = try await LegacySession.token()
                KeyHandoff.initialize(hasLegacyUser: token != nil || LegacySession.retired)
                reply(true, [
                    "token": token ?? NSNull(),
                    "signedIn": token != nil,
                    "language": host.language(),
                    "guestIdentityId": LegacySession.guestIdentityId(),
                    "capabilities": Self.capabilities
                ], nil)

            case "home.retireSession":
                KeyHandoff.clearSavedScope()
                ble.accept([], historyTag: nil, historyName: nil)
                await LegacySession.retire()
                reply(true, nil, nil)

            case "home.devices":
                guard let devices = json["devices"] as? [[String: Any]] else { throw RequestError.invalid }
                ble.accept(devices, historyTag: json["historyTag"] as? String, historyName: json["historyName"] as? String)
                if !devices.isEmpty { host.requestBle() }
                reply(true, nil, nil)

            case "home.offlineDevices":
                ble.restoreSaved()
                host.requestBle()
                reply(true, ["devices": KeyHandoff.offlineDevices(), "language": host.language()], nil)
                ble.snapshot()

            case "home.localKeys":
                reply(true, KeyHandoff.pending().map { key -> [String: Any] in
                    var json = key.webJSON
                    json["deviceName"] = KeyHandoff.name(key)
                    json["keyLevel"] = KeyHandoff.level(key)
                    return json
                }, nil)

            case "home.deviceKey":
                guard let id = json["deviceUUID"] as? String, KeyHandoff.isInScope(id), let key = KeyHandoff.key(id) else {
                    throw RequestError.invalid
                }
                reply(true, key.webJSON, nil)

            case "home.keysUploaded":
                guard let id = json["deviceUUID"] as? String else { throw RequestError.invalid }
                KeyHandoff.acknowledge(id)
                reply(true, nil, nil)

            case "home.command", "home.scripts":
                ble.command(json) { success, error in reply(success, nil, error) }

            case "home.dropDevice":
                guard let id = json["deviceUUID"] as? String else { throw RequestError.invalid }
                ble.drop(id)
                KeyHandoff.acknowledge(id)
                reply(true, nil, nil)

            case "home.scanStart":
                registration.removedDevices = Set((json["removedDevices"] as? [String] ?? []).map { $0.uppercased() })
                host.startDiscovery()
                reply(true, nil, nil)

            case "home.scanStop":
                host.stopDiscovery()
                reply(true, nil, nil)

            case "home.register":
                guard let id = json["deviceUUID"] as? String else { throw RequestError.invalid }
                guard network.currentPath.status == .satisfied else {
                    return reply(false, nil, "Registration requires network")
                }
                registration.register(id) { [ble] success, error in
                    if success { ble.peripheralSettings.registered(id) }
                    reply(success, success ? Self.registeredKey(id) : nil, error)
                }

            case "home.lockSettings":
                reply(true, try await LockSettings.handle(ble, json), nil)

            case "home.botSettings":
                reply(true, try await BotSettings.handle(ble, json), nil)

            case "home.hubSettings":
                reply(true, try await ble.hubSettings.handle(json), nil)

            case "home.peripheralSettings":
                reply(true, try await ble.peripheralSettings.handle(json), nil)

            case "home.devicePreferences":
                let id = json["deviceUUID"] as? String ?? ""
                guard ble.device(id) != nil else { throw RequestError.invalid }
                reply(true, AutoUnlock.shared.snapshot(id), nil)

            case "home.autoUnlock":
                reply(true, try AutoUnlock.shared.handle(json) {
                    host.openExternal(URL(string: UIApplication.openSettingsURLString)!)
                }, nil)

            case "home.currentLocation":
                reply(true, await DeviceLocation.current() ?? NSNull(), nil)

            case "home.firmwareStatus":
                reply(true, BleFirmwareUpdate.shared.snapshot(), nil)

            case "home.firmwareStart":
                guard let device = ble.device(json["deviceUUID"] as? String ?? "") else { throw RequestError.invalid }
                reply(true, try BleFirmwareUpdate.shared.start(device, url: json["url"] as? String ?? "") { [ble] in ble.reconnect() }, nil)

            case "home.firmwareInfo":
                guard let device = ble.device(json["deviceUUID"] as? String ?? "") else { throw RequestError.invalid }
                reply(true, ["productType": Int(device.productModel.rawValue), "firmwareDir": InternalTest.firmwareDir], nil)

            case "home.internalTest":
                InternalTest.handle(ble, json, reply: reply)

            case "home.pushInfo":
                guard let token = await PushManager.shared.pushToken() else { throw RequestError.invalid }
                AutoUnlock.shared.refreshNotificationSetting()
                reply(true, [
                    "pushToken": token,
                    "appIdentifyId": LegacySession.guestIdentityId(),
                    "env": await AppEnvironment.collect(),
                    "language": host.language(),
                    "enabled": AutoUnlock.shared.notificationsEnabled,
                    "platform": PushManager.platform
                ], nil)

            case "home.route":
                host.showRoute(AppRoute(json))
                reply(true, nil, nil)

            case "home.openWebPage":
                let url = try Self.url(json, schemes: ["https"])
                host.openWebPage(url)
                reply(true, nil, nil)

            case "home.external":
                let url = try Self.url(json, schemes: ["https", "http", "mailto", "tel"])
                host.openExternal(url)
                reply(true, nil, nil)

            case "home.haptic":
                host.haptic(min(max(json["duration"] as? Int ?? 0, 0), 100))
                reply(true, nil, nil)

            case "home.voiceShortcut":
                let id = (json["deviceUUID"] as? String ?? "").uppercased()
                guard let operation = SesameOperation(rawValue: json["operation"] as? String ?? ""),
                      let device = SesameDeviceEntity.all().first(where: { $0.id == id }), operation.supports(device.kind),
                      let presenter = host.presenter() else { throw RequestError.invalid }
                await VoiceShortcut.shared.present(operation, name: device.name, from: presenter)
                reply(true, nil, nil)

            case "home.notificationSettings":
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    host.openExternal(url)
                }
                reply(true, nil, nil)

            case "home.firmwareTrace":
#if DEBUG
                let transport = json["transport"] as? String ?? ""
                let phase = json["phase"] as? String ?? ""
                if ["ble", "gateway"].contains(transport), ["start", "progress", "completed", "failed", "version"].contains(phase) {
                    L.d("transport=\(transport) phase=\(phase) progress=\(json["progress"] as? Int ?? -1)", tag: "SesameFirmware")
                }
#endif
                reply(true, nil, nil)

            default:
                reply(false, nil, "This native capability is not available in this version")
            }
        } catch is CancellationError {
        } catch {
            reply(false, nil, "Native request failed; retry when connected")
        }
    }

    private static func registeredKey(_ id: String) -> [String: Any]? {
        guard let key = KeyStore.shared.key(id) else { return nil }
        var json = key.webJSON
        json["keyLevel"] = 0
        json["deviceName"] = CHProductModel.deviceModeulFromString(key.deviceModel)?.deviceModelName() ?? key.deviceModel
        return json
    }

    enum RequestError: Error {
        case invalid
    }

    private static func url(_ json: [String: Any], schemes: Set<String>) throws -> URL {
        guard let text = json["url"] as? String, let url = URL(string: text),
              let scheme = url.scheme?.lowercased(), schemes.contains(scheme) else {
            throw URLError(.unsupportedURL)
        }
        return url
    }
}

extension CHDeviceKey {
    var webJSON: [String: Any] {
        [
            "deviceUUID": deviceUUID.uuidString.uppercased(),
            "deviceModel": deviceModel,
            "keyIndex": keyIndex,
            "secretKey": secretKey,
            "sesame2PublicKey": sesame2PublicKey
        ]
    }
}
