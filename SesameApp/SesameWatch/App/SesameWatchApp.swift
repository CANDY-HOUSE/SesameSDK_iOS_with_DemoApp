import SwiftUI

@main
struct SesameWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var devices = WatchDevices.shared

    init() {
        WatchDevices.shared.start()
        WatchKeyReceiver.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(devices)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: devices.resume()
            case .background: devices.pause()
            default: break
            }
        }
    }
}
