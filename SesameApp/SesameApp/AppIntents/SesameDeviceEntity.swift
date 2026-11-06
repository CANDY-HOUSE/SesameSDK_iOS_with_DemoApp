import AppIntents
import SesameSDK

enum SesameDeviceKind {
    case lock, bot, bike

    init?(model: String) {
        switch CHProductModel.deviceModeulFromString(model) {
        case .sesame2, .sesame4, .sesame5, .sesame5Pro, .sesame5US, .sesame6, .sesame6Pro, .sesame6ProSlidingDoor, .sesameMiwa: self = .lock
        case .sesameBot, .sesameBot2, .sesameBot3: self = .bot
        case .bikeLock, .bikeLock2, .bikeLock3: self = .bike
        default: return nil
        }
    }
}

enum SesameOperation: String {
    case toggle, lock, unlock

    func supports(_ kind: SesameDeviceKind) -> Bool {
        switch self {
        case .toggle: return kind != .bike
        case .lock: return kind == .lock
        case .unlock: return kind != .bot
        }
    }

    /// Item codes the gateway forwards to the device; the native app sent plain click (89) to every Bot.
    func command(_ kind: SesameDeviceKind) -> UInt8 {
        switch (kind, self) {
        case (.bot, _): return 89
        case (_, .lock): return 82
        case (_, .unlock): return 83
        default: return 88
        }
    }
}

enum SesameIntentError: Error, CustomLocalizedStringResourceConvertible {
    case unsupported
    case unreachable(String)
    case failed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unsupported: return "This device does not support this action"
        case .unreachable(let name): return "Unable to connect to \(name)"
        case .failed(let name): return "Failed to operate \(name)"
        }
    }
}

/// A device with a saved key that Siri can operate. Each target lists them in `all()`, next to its `SesameIntentRunner`.
struct SesameDeviceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sesame Device"
    static var defaultQuery = SesameDeviceQuery()

    let id: String
    let name: String
    let kind: SesameDeviceKind

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    /// Shortcuts added in the native app only carry the device name.
    static func named(_ name: String?) -> SesameDeviceEntity? {
        guard let name = name?.lowercased(), !name.isEmpty else { return nil }
        return all().first { $0.name.lowercased() == name }
    }
}

struct SesameDeviceQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [SesameDeviceEntity] {
        SesameDeviceEntity.all().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [SesameDeviceEntity] {
        SesameDeviceEntity.all().filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [SesameDeviceEntity] {
        SesameDeviceEntity.all()
    }
}
