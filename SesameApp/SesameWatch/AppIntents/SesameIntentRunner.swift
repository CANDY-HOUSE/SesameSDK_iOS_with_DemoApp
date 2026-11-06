import AppIntents
import Foundation
import SesameGateway
import SesameSDK

/// Runs a Siri command on the Watch the same way as on the iPhone: Bluetooth first; within 10 seconds,
/// if Bluetooth has not logged in and the shadow shows a gateway online, send it through the gateway.
@MainActor
enum SesameIntentRunner {
    private final class GatewayState {
        var online = false
    }

    static func run(_ operation: SesameOperation, on target: SesameDeviceEntity) async throws {
        guard operation.supports(target.kind) else { throw SesameIntentError.unsupported }
        guard let key = KeyStore.shared.key(target.id) else { throw SesameIntentError.unreachable(target.name) }
        let ble = WatchDevices.shared
        ble.start()
        ble.startIntent(target.id)
        defer { ble.stopIntent(target.id) }
        let gateway = GatewayState()
        let lookup = Task {
            try WatchGateway.configure()
            gateway.online = try await SesameGateway.shadow(deviceId: key.deviceUUID).gatewayOnline
        }
        defer { lookup.cancel() }
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if ble.device(target.id)?.deviceStatus.loginStatus == .logined {
                guard await ble.command(operation, target.id) else { throw SesameIntentError.failed(target.name) }
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
}

/// Devices the iPhone synced to this Watch.
extension SesameDeviceEntity {
    static func all() -> [SesameDeviceEntity] {
        WatchStore.devices().map { SesameDeviceEntity(id: $0.id, name: $0.name, kind: $0.kind) }
    }
}
