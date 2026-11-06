import CoreBluetooth
import CryptoKit
import Foundation
import NordicDFU
import SesameSDK

/// One app-wide DFU session, surviving page navigation; Biz reads its state through firmwareStatus.
final class BleFirmwareUpdate: NSObject {
    static let shared = BleFirmwareUpdate()

    private var sessionId: Int64 = 0
    private var deviceId: String?
    private var progress = 0
    private var state = "idle"
    private var controller: DFUServiceController?
    private var reconnect: (() -> Void)?
    /// Files downloaded by this process, as on Android; files left in tmp by an earlier launch are downloaded again.
    private var cachedFiles: [URL: URL] = [:]

    func active(_ id: String) -> Bool {
        deviceId == id.uppercased() && ["downloading", "updating"].contains(state)
    }

    func snapshot() -> [String: Any] {
        ["deviceUUID": deviceId ?? NSNull(), "state": state, "progress": progress, "sessionId": sessionId]
    }

    func start(_ device: CHDevice, url text: String, reconnect: @escaping () -> Void) throws -> [String: Any] {
        try require(!["downloading", "updating"].contains(state) && device.loggedIn)
        guard let source = URL(string: text), source.scheme == "https", source.host == "firmware.candyhouse.co",
              source.port == nil, source.user == nil, source.path.hasSuffix(".zip") else { throw BleError.invalid }
        let path = source.path.hasPrefix("/") ? String(source.path.dropFirst()) : source.path
        try require(!path.contains("/") || source.path.hasPrefix("/dev/"))
        sessionId = Int64(Date().timeIntervalSince1970 * 1000)
        deviceId = device.uuid
        progress = 0
        state = "downloading"
        self.reconnect = reconnect
        let session = sessionId
        Task { @MainActor in
            do {
                let data = try await self.download(source)
                guard session == self.sessionId else { return }
                try require(device.loggedIn)
                let target: CBPeripheral? = try await bleResult(timeout: 15) { device.updateFirmware(result: $0) }
                guard let target else { throw BleError.unavailable }
                let firmware = try DFUFirmware(zipFile: data, type: .application)
                let initiator = DFUServiceInitiator().with(firmware: firmware)
                initiator.delegate = self
                initiator.progressDelegate = self
                initiator.packetReceiptNotificationParameter = 12
                initiator.dataObjectPreparationDelay = 0.4
                initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
                self.state = "updating"
                self.controller = initiator.start(target: target)
                if self.controller == nil { self.finish("failed") }
            } catch {
                guard session == self.sessionId else { return }
                self.state = "failed"
                self.progress = -7
                self.reconnect?()
            }
        }
        return snapshot()
    }

    private static func cacheURL(_ source: URL) -> URL {
        let key = SHA256.hash(data: Data(source.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        return FileManager.default.temporaryDirectory.appendingPathComponent("firmware-runtime-\(key).zip")
    }

    @MainActor
    private func download(_ source: URL) async throws -> Data {
        if let file = cachedFiles[source], let data = try? Data(contentsOf: file), !data.isEmpty { return data }
        let cached = Self.cacheURL(source)
        removeStaleFiles()
        var request = URLRequest(url: source, timeoutInterval: 15)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        try require((response as? HTTPURLResponse)?.statusCode == 200 && response.url?.host == source.host)
        try require(!data.isEmpty && data.count <= 8 * 1024 * 1024)
        if (try? data.write(to: cached, options: .atomic)) != nil { cachedFiles[source] = cached }
        return data
    }

    /// Each firmware version has its own URL, so files from earlier launches would pile up in tmp.
    @MainActor
    private func removeStaleFiles() {
        let directory = FileManager.default.temporaryDirectory
        let kept = Set(cachedFiles.values.map(\.lastPathComponent))
        for name in (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        where name.hasPrefix("firmware-runtime-") && !kept.contains(name) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    private func stage(_ value: Int) {
        guard state == "updating" else { return }
        progress = value
    }

    private func finish(_ result: String) {
        guard state == "updating" else { return }
        state = result
        progress = result == "completed" ? -6 : -7
        controller = nil
        reconnect?()
    }
}

extension BleFirmwareUpdate: DFUServiceDelegate, DFUProgressDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .connecting: stage(-1)
        case .starting: stage(-2)
        case .enablingDfuMode: stage(-3)
        case .validating: stage(-4)
        case .disconnecting: stage(-5)
        case .completed: finish("completed")
        case .aborted: finish("failed")
        default: break
        }
    }

    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        finish("failed")
    }

    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        guard state == "updating" else { return }
        self.progress = ((part - 1) * 100 + progress) / max(totalParts, 1)
    }
}
