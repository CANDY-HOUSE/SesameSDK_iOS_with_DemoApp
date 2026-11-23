import Foundation
import Photos
import UniformTypeIdentifiers

/// Receives a photo or video from Biz in base64 slices and adds it to the photo library.
/// Slices go to a temporary file first, so a long recording never sits in memory as one string.
actor MediaSaver {
    enum SaveError: Error {
        case invalid, unknownTransfer, permissionDenied
    }

    private enum Kind: String {
        case image, video

        var mimePrefix: String { "\(rawValue)/" }
        var resource: PHAssetResourceType { self == .image ? .photo : .video }
    }

    private struct Transfer {
        let file: URL
        let kind: Kind
        let name: String
        let handle: FileHandle
    }

    private static let staleInterval: TimeInterval = 60 * 60

    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent("media-save", isDirectory: true)
    private var transfers: [String: Transfer] = [:]

    /// begin → ["id": …]; append (base64 `data`) / commit / abort → nil. Slices are appended in arrival order.
    func handle(_ json: [String: Any]) async throws -> [String: Any]? {
        let id = json["id"] as? String ?? ""
        switch json["operation"] as? String {
        case "begin":
            return try await begin(json)

        case "append":
            guard let transfer = transfers[id] else { throw SaveError.unknownTransfer }
            guard let text = json["data"] as? String, let data = Data(base64Encoded: text) else { throw SaveError.invalid }
            try transfer.handle.write(contentsOf: data)

        case "commit":
            guard let transfer = transfers.removeValue(forKey: id) else { throw SaveError.unknownTransfer }
            defer { try? FileManager.default.removeItem(at: transfer.file) }
            try transfer.handle.close()
            try await publish(transfer)

        case "abort":
            if let transfer = transfers.removeValue(forKey: id) {
                try? transfer.handle.close()
                try? FileManager.default.removeItem(at: transfer.file)
            }

        default:
            throw SaveError.invalid
        }
        return nil
    }

    private func begin(_ json: [String: Any]) async throws -> [String: Any] {
        guard let kind = Kind(rawValue: json["kind"] as? String ?? ""),
              let mime = (json["mimeType"] as? String)?.split(separator: ";").first?.trimmingCharacters(in: .whitespaces).lowercased(),
              mime.hasPrefix(kind.mimePrefix) else { throw SaveError.invalid }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.permissionDenied }

        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        // A page reload or killed process can leave slices behind; nothing should take this long.
        let files = (try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for file in files {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if Date().timeIntervalSince(modified) > Self.staleInterval { try? manager.removeItem(at: file) }
        }

        let id = UUID().uuidString
        let name = Self.displayName(json["fileName"] as? String, mime: mime)
        // Photos reads the type from the extension, so the temporary file keeps it.
        let file = directory.appendingPathComponent(id).appendingPathExtension((name as NSString).pathExtension)
        guard manager.createFile(atPath: file.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
        transfers[id] = Transfer(file: file, kind: kind, name: name, handle: try FileHandle(forWritingTo: file))
        return ["id": id]
    }

    private func publish(_ transfer: Transfer) async throws {
        let size = (try FileManager.default.attributesOfItem(atPath: transfer.file.path)[.size] as? NSNumber)?.intValue ?? 0
        guard size > 0 else { throw SaveError.invalid }
        let file = transfer.file, name = transfer.name, type = transfer.kind.resource
        try await PHPhotoLibrary.shared().performChanges {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = name
            options.shouldMoveFile = true
            PHAssetCreationRequest.forAsset().addResource(with: type, fileURL: file, options: options)
        }
    }

    private static func displayName(_ requested: String?, mime: String) -> String {
        let fallbackExtension = UTType(mimeType: mime)?.preferredFilenameExtension ?? String(mime.split(separator: "/").last ?? "")
        let last = (requested ?? "").components(separatedBy: CharacterSet(charactersIn: "/\\:")).last ?? ""
        var name = String(last.trimmingCharacters(in: .whitespacesAndNewlines).drop { $0 == "." }.prefix(120))
        if name.isEmpty { name = "Sesame_\(Int(Date().timeIntervalSince1970))" }
        return (name as NSString).pathExtension.isEmpty ? "\(name).\(fallbackExtension)" : name
    }
}
