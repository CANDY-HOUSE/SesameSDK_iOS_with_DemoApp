import Foundation
import WatchConnectivity

/// Receives the keys the iPhone sends with `updateApplicationContext` (`WatchKeySync`).
final class WatchKeyReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchKeyReceiver()

    func start() {
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            guard WatchStore.apply(applicationContext) else { return }
            WatchDevices.shared.reload()
        }
    }
}
