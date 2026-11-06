import Foundation
import SesameSDK

/// One Biz credential page: device list state and commands; names and cloud sync live in Biz.
final class CredentialSession: CredentialEvents {
    let kind: String
    let token: String
    private let device: CHDevice
    private let channel: CredentialChannel
    private let onChange: () -> Void
    private var items: [(id: String, item: [String: Any])] = []
    private var revision = 0
    private var failureRevision = 0
    private var complete = false
    private var loading = true
    private var listStarted = false
    private var mode = 0
    private var closed = false
    private var loadFailed = false
    private var loadTimer: DispatchWorkItem?
    private var changeScheduled = false
    private var importing = false
    private var importProgress = 0
    private var importRevision = 0
    private var importError: String?

    init(device: CHDevice, kind: String, token: String, onChange: @escaping () -> Void) throws {
        self.device = device
        self.kind = kind
        self.token = token
        self.onChange = onChange
        channel = try CredentialChannel.of(device, kind: kind)
    }

    func snapshot() -> [String: Any] {
        [
            "kind": kind, "session": token, "revision": revision, "complete": complete, "loading": loading,
            "loadFailed": loadFailed, "mode": mode, "failureRevision": failureRevision, "importing": importing,
            "importProgress": importProgress, "importRevision": importRevision, "importError": importError ?? NSNull(),
            "items": items.map(\.item)
        ]
    }

    private func update(_ block: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard !self.closed else { return }
            block()
            self.scheduleChange()
        }
    }

    /// A device streams hundreds of items within a fraction of a second; one snapshot per 100 ms keeps the page responsive.
    private func scheduleChange() {
        guard !changeScheduled else { return }
        changeScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.changeScheduled = false
            if !self.closed { self.onChange() }
        }
    }

    private func waitForList() {
        loadTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.listFailed() }
        loadTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }

    private func listFailed() {
        update {
            guard !self.complete else { return }
            self.loading = false
            self.loadFailed = true
            self.loadTimer?.cancel()
        }
    }

    /// Empty card/passcode reads can ACK without FIRST/LAST; only LAST confirms a full list for cloud replacement.
    private func acknowledged() {
        update {
            guard !self.listStarted, !self.complete else { return }
            self.loading = false
            self.loadFailed = false
            self.loadTimer?.cancel()
        }
    }

    func started() {
        update {
            self.listStarted = true
            self.loading = true
            self.complete = false
            self.loadFailed = false
            self.items.removeAll()
            self.waitForList()
        }
    }

    func ended() {
        update {
            self.loading = false
            self.complete = true
            self.loadFailed = false
            self.loadTimer?.cancel()
            self.revision += 1
        }
    }

    func received(_ id: String, name: String, type: UInt8, changed: Bool) {
        update {
            let item: [String: Any] = ["credentialId": id, "rawName": name, "type": Int(type)]
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].item = item
            } else {
                self.items.append((id, item))
            }
            if changed {
                self.revision += 1
            } else if !self.complete {
                self.listStarted = true
                self.loading = true
                self.waitForList()
            }
        }
    }

    func deleted(_ id: String) {
        update {
            self.items.removeAll { $0.id == id }
            self.revision += 1
        }
    }

    func deleteFailed() { update { self.failureRevision += 1 } }
    func modeChanged(_ mode: UInt8) { update { self.mode = Int(mode) } }

    func open() {
        waitForList()
        channel.attach(self)
        Task { @MainActor in
            if let mode: UInt8 = try? await bleResult(timeout: 4, { self.channel.readMode($0) }) { self.modeChanged(mode) }
        }
        channel.requestList(acknowledged: { [weak self] in self?.acknowledged() }, failed: { [weak self] in self?.listFailed() })
    }

    @MainActor
    private func setMode(_ value: Int) async throws {
        try require(value == 1 || value == Int(channel.idleMode))
        let _: CHEmpty = try await bleResult(timeout: 8) { channel.setMode(UInt8(value), $0) }
        mode = value
    }

    @MainActor
    func command(_ op: String, _ json: [String: Any]) async throws {
        switch op {
        case "credentialMode":
            try await setMode(json["value"] as? Int ?? -1)
        case "credentialAdd":
            let value = try bytes(json["value"] as? String ?? "")
            let _: CHEmpty = try await bleResult(timeout: 8) { channel.add(value, json["name"] as? String ?? "", $0) }
        case "credentialImport":
            try startImport(try bytes(json["data"] as? String ?? ""))
        case "credentialRename":
            let id = json["id"] as? String ?? ""
            try require(items.contains { $0.id == id })
            let name = (json["nameUUID"] as? String ?? "").replacingOccurrences(of: "-", with: "")
            try require(name.count == 32 && name.allSatisfy(\.isHexDigit))
            let _: CHEmpty = try await bleResult(timeout: 8) { channel.rename(id, name, $0) }
            if let index = items.firstIndex(where: { $0.id == id }) { items[index].item["rawName"] = name }
            revision += 1
        case "credentialDelete":
            let id = json["id"] as? String ?? ""
            try require(items.contains { $0.id == id })
            let _: CHEmpty = try await bleResult(timeout: 8) { channel.delete(id, $0) }
            if !channel.deleteConfirmedByEvent { deleted(id) }
        default:
            throw BleError.unsupported
        }
    }

    private func bytes(_ hex: String) throws -> Data {
        try require(!hex.isEmpty && hex.count % 2 == 0 && hex.allSatisfy(\.isHexDigit))
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            data.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return data
    }

    /// The SDK sends 209-byte packets 4 s apart, longer than a bridge request; progress and result go out in the snapshot.
    private func startImport(_ data: Data) throws {
        try require(!importing && data.count <= Int(Int16.max))
        importing = true
        importProgress = 0
        importError = nil
        channel.batchAdd(data, progress: { [weak self] current, total in
            self?.update {
                if self?.importing == true, total > 0 { self?.importProgress = current * 100 / total }
            }
        }) { [weak self] result in
            self?.update {
                guard let self else { return }
                self.importing = false
                if case .failure(let error) = result {
                    self.importError = (error as NSError).localizedDescription
                } else {
                    self.importProgress = 100
                }
                self.importRevision += 1
            }
        }
    }

    /// Restores the idle mode when the device is still connected; the returned task finishes when that is done.
    func close() -> Task<Void, Never>? {
        guard !closed else { return nil }
        closed = true
        loadTimer?.cancel()
        channel.detach()
        guard device.loggedIn else { return nil }
        let channel = channel
        return Task { @MainActor in
            let _: CHEmpty? = try? await bleResult(timeout: 4) { channel.setMode(channel.idleMode, $0) }
        }
    }
}
