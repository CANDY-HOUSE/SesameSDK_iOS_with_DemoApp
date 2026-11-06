import AppIntents

/// Phrases that work without setup. Device phrases follow `SesameDeviceQuery.suggestedEntities()`;
/// call `updateAppShortcutParameters()` whenever the device list changes.
struct SesameShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: UnlockSesame(), phrases: [
            "Unlock \(.applicationName)",
            "Unlock \(\.$device) with \(.applicationName)"
        ])
        AppShortcut(intent: LockSesame(), phrases: [
            "Lock \(.applicationName)",
            "Lock \(\.$device) with \(.applicationName)"
        ])
        AppShortcut(intent: ToggleSesame(), phrases: [
            "Toggle \(.applicationName)",
            "Toggle \(\.$device) with \(.applicationName)"
        ])
    }
}
