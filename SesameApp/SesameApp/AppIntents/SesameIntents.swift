import AppIntents

// The class names and the `name` parameter match the native app's SiriKit intents, so phrases and shortcuts
// added there keep working after the upgrade. New shortcuts pick the device instead.

struct ToggleSesame: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "ToggleSesameIntent"
    static var title: LocalizedStringResource = "Toggle Sesame"

    @Parameter(title: "Device")
    var device: SesameDeviceEntity?

    @Parameter(title: "Name")
    var name: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Toggle \(\.$device)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let target = device ?? SesameDeviceEntity.named(name) else { throw $device.needsValueError() }
        try await SesameIntentRunner.run(.toggle, on: target)
        return .result(dialog: "Toggled \(target.name)")
    }
}

struct LockSesame: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "LockSesameIntent"
    static var title: LocalizedStringResource = "Lock Sesame"

    @Parameter(title: "Device")
    var device: SesameDeviceEntity?

    @Parameter(title: "Name")
    var name: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Lock \(\.$device)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let target = device ?? SesameDeviceEntity.named(name) else { throw $device.needsValueError() }
        try await SesameIntentRunner.run(.lock, on: target)
        return .result(dialog: "Locked \(target.name)")
    }
}

struct UnlockSesame: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "UnlockSesameIntent"
    static var title: LocalizedStringResource = "Unlock Sesame"

    @Parameter(title: "Device")
    var device: SesameDeviceEntity?

    @Parameter(title: "Name")
    var name: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Unlock \(\.$device)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let target = device ?? SesameDeviceEntity.named(name) else { throw $device.needsValueError() }
        try await SesameIntentRunner.run(.unlock, on: target)
        return .result(dialog: "Unlocked \(target.name)")
    }
}
