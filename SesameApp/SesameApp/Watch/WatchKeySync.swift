import Foundation
import SesameSDK
import UIKit
import WatchConnectivity

/// Sends the Watch the latest full set of keys it can operate (locks, Bots, Bikes).
/// The Watch replaces its own Keychain copy with each context; an empty list clears it.
final class WatchKeySync: NSObject, WCSessionDelegate {
    static let shared = WatchKeySync()

    private var sent: NSDictionary?

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Called on the main thread with BleController.
    func push() {
        let ble = BleController.shared
        // Names and gateways are current only after Biz sent the list; before the first unlock the Keychain reads as empty.
        guard ble.receivedCloudList, UIApplication.shared.isProtectedDataAvailable, WCSession.isSupported(),
              WCSession.default.activationState == .activated, WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        let gateways = BleBackend.shared.gatewayDevices
        let devices: [[String: Any]] = KeyHandoff.offlineDevices().compactMap { row in
            guard let id = row["deviceUUID"] as? String, let model = row["deviceModel"] as? String,
                  SesameDeviceKind(model: model) != nil, let key = KeyStore.shared.key(id) else { return nil }
            return [
                "deviceUUID": id,
                "deviceModel": model,
                "deviceName": row["deviceName"] as? String ?? model,
                "keyIndex": key.keyIndex,
                "secretKey": key.secretKey,
                "sesame2PublicKey": key.sesame2PublicKey,
                "gateway": gateways.contains(id.uppercased())
            ]
        }
        var context: [String: Any] = ["devices": devices, "historyTag": ble.historyTag()]
        if let name = ble.os2HistoryTag() { context["historyName"] = name }
        let dictionary = context as NSDictionary
        guard sent != dictionary else { return }
        do {
            try WCSession.default.updateApplicationContext(context)
            sent = dictionary
        } catch {}
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        DispatchQueue.main.async { self.push() }
    }

    /// The Watch app was installed or another Watch was paired.
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.sent = nil
            self.push()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Switching to another Watch deactivates the session; activate again for the new one.
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
