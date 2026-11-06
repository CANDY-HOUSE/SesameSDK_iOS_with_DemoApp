import Intents
import IntentsUI
import UIKit

// The "Add to Siri" sheet only takes SiriKit intents, so Sesame2Intents.intentdefinition stays in the app;
// running the phrase goes to the App Intent that migrates the same class.
@MainActor
final class VoiceShortcut: NSObject {
    static let shared = VoiceShortcut()

    func present(_ operation: SesameOperation, name: String, from presenter: UIViewController) async {
        let intent = Self.intent(operation)
        intent.setValue(name, forKey: "name")
        intent.suggestedInvocationPhrase = String(localized: "Open Sesame")
        guard let shortcut = INShortcut(intent: intent) else { return }
        let shortcuts = (try? await INVoiceShortcutCenter.shared.allVoiceShortcuts()) ?? []
        let existing = shortcuts.first { voiceShortcut in
            guard let added = voiceShortcut.shortcut.intent, type(of: added) == type(of: intent) else { return false }
            return (added.value(forKey: "name") as? String)?.lowercased() == name.lowercased()
        }
        let controller: UIViewController
        if let existing {
            let edit = INUIEditVoiceShortcutViewController(voiceShortcut: existing)
            edit.delegate = self
            controller = edit
        } else {
            let add = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            add.delegate = self
            controller = add
        }
        controller.modalPresentationStyle = .formSheet
        presenter.present(controller, animated: true)
    }

    private static func intent(_ operation: SesameOperation) -> INIntent {
        switch operation {
        case .toggle: return ToggleSesameIntent()
        case .lock: return LockSesameIntent()
        case .unlock: return UnlockSesameIntent()
        }
    }
}

// Same as the classes Xcode generates from Sesame2Intents.intentdefinition, which the synchronized folder copies as a resource only.
@objc(ToggleSesameIntent)
final class ToggleSesameIntent: INIntent {
    @NSManaged var name: String?
}

@objc(LockSesameIntent)
final class LockSesameIntent: INIntent {
    @NSManaged var name: String?
}

@objc(UnlockSesameIntent)
final class UnlockSesameIntent: INIntent {
    @NSManaged var name: String?
}

extension VoiceShortcut: INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    nonisolated func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        Task { @MainActor in controller.dismiss(animated: true) }
    }

    nonisolated func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        Task { @MainActor in controller.dismiss(animated: true) }
    }

    nonisolated func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        Task { @MainActor in controller.dismiss(animated: true) }
    }

    nonisolated func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        Task { @MainActor in controller.dismiss(animated: true) }
    }

    nonisolated func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        Task { @MainActor in controller.dismiss(animated: true) }
    }
}
