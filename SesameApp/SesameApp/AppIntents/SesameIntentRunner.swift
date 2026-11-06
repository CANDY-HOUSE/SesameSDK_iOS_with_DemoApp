import AppIntents
import Foundation
import SesameGateway
import SesameSDK

/// Runs a Siri command in the app process, as the native Siri extension did: Bluetooth first;
/// within 10 seconds, if Bluetooth has not logged in and the shadow shows a gateway online, send it through the gateway.
@MainActor
enum SesameIntentRunner {
    private final class GatewayState {
        var online = false
    }

    static func run(_ operation: SesameOperation, on target: SesameDeviceEntity) async throws {
        guard operation.supports(target.kind) else { throw SesameIntentError.unsupported }
        guard let key = KeyStore.shared.key(target.id) else { throw SesameIntentError.unreachable(target.name) }
        let ble = BleController.shared
        ble.restoreSaved()
        ble.startIntent()
        defer { ble.stopIntent() }
        let gateway = GatewayState()
        let lookup = Task {
            try LegacySession.configure()
            gateway.online = try await SesameGateway.shadow(deviceId: key.deviceUUID).gatewayOnline
        }
        defer { lookup.cancel() }
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if ble.device(target.id)?.deviceStatus.loginStatus == .logined {
                guard await bleCommand(operation, target.id) else { throw SesameIntentError.failed(target.name) }
                return
            }
            if gateway.online {
                do {
                    try await SesameGateway.send(command: operation.command(target.kind), deviceId: key.deviceUUID,
                                                 secretKey: key.secretKey, history: ble.gatewayHistoryTag())
                } catch {
                    throw SesameIntentError.failed(target.name)
                }
                return
            }
            try await Task.sleep(nanoseconds: 300_000_000)
        }
        throw SesameIntentError.unreachable(target.name)
    }

    private static func bleCommand(_ operation: SesameOperation, _ id: String) async -> Bool {
        await withCheckedContinuation { continuation in
            BleController.shared.command(["deviceUUID": id, "operation": operation.rawValue]) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

/// Names come from Biz (`home.devices`) or the native app's database.
extension SesameDeviceEntity {
    static func all() -> [SesameDeviceEntity] {
        KeyHandoff.offlineDevices().compactMap { row in
            guard let id = row["deviceUUID"] as? String, let model = row["deviceModel"] as? String,
                  let kind = SesameDeviceKind(model: model) else { return nil }
            return SesameDeviceEntity(id: id, name: row["deviceName"] as? String ?? model, kind: kind)
        }
    }
}
