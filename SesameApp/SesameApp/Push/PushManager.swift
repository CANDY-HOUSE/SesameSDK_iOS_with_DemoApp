import UIKit
import UserNotifications

/// APNs token and notification taps; Biz owns subscription, binding and what a push means.
@MainActor
final class PushManager: NSObject, UNUserNotificationCenterDelegate {
    enum Target {
        case route(String)
        case webPage(URL)
    }

    static let shared = PushManager()

    var changed: (() -> Void)?
    var open: ((Target) -> Bool)?
    private(set) var token: String? = UserDefaults.standard.string(forKey: "apnsToken")
    private var waiters: [CheckedContinuation<String?, Never>] = []
    private var pending: Target?

    static var platform: String {
#if DEBUG
        "ios_sandbox"
#else
        "ios"
#endif
    }

    func start(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async { AutoUnlock.shared.refreshNotificationSetting() }
        }
        application.registerForRemoteNotifications()
    }

    func registered(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        let previous = token
        token = hex
        UserDefaults.standard.set(hex, forKey: "apnsToken")
        waiters.forEach { $0.resume(returning: hex) }
        waiters.removeAll()
        if previous != hex { changed?() }
    }

    func registrationFailed() {
        waiters.forEach { $0.resume(returning: token) }
        waiters.removeAll()
    }

    func pushToken() async -> String? {
        if let token { return token }
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { self.registrationFailed() }
        }
    }

    func received() {
        changed?()
    }

    /// Delivers a tap that arrived before the page could navigate.
    func deliverPending() {
        guard let target = pending, open?(target) == true else { return }
        pending = nil
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let silent = content.userInfo["event"] as? String == "device" || (content.title.isEmpty && content.body.isEmpty)
        Task { @MainActor in self.received() }
        completionHandler(silent ? [] : [.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let route = info["route"] as? String
        let url = info["url"] as? String
        let action = info["messageAction"] as? String
        Task { @MainActor in
            self.received()
            if let route, route.hasPrefix("/"), !route.hasPrefix("//") {
                self.pending = .route(route)
            } else if let url, let target = URL(string: url), target.scheme == "https", action == nil || action == "" || action == "open_webview" {
                self.pending = .webPage(target)
            }
            self.deliverPending()
            completionHandler()
        }
    }
}
