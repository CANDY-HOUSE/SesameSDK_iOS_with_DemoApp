import Foundation
import SesameSDK

protocol CredentialEvents: AnyObject {
    func received(_ id: String, name: String, type: UInt8, changed: Bool)
    func started()
    func ended()
    func modeChanged(_ mode: UInt8)
    func deleted(_ id: String)
    func deleteFailed()
}

/// Maps one credential kind onto its SDK capability; list and session semantics stay in CredentialSession.
class CredentialChannel: NSObject {
    weak var events: CredentialEvents?
    /// Mode restored when the session closes; the only accepted mode besides enrolment (1).
    var idleMode: UInt8 { 0 }
    /// Face/palm deletion completes on its device notification, not on the command ACK.
    var deleteConfirmedByEvent: Bool { false }

    static func of(_ device: CHDevice, kind: String) throws -> CredentialChannel {
        switch kind {
        case "card": if let capable = device as? CHCardCapable { return CardChannel(capable) }
        case "fingerprint": if let capable = device as? CHFingerPrintCapable { return FingerPrintChannel(capable) }
        case "passcode": if let capable = device as? CHPassCodeCapable { return PassCodeChannel(capable) }
        case "face": if let capable = device as? CHFaceCapable { return FaceChannel(capable) }
        case "palm": if let capable = device as? CHPalmCapable { return PalmChannel(capable) }
        default: break
        }
        throw BleError.unsupported
    }

    func attach(_ events: CredentialEvents) { self.events = events }
    func detach() {}
    func readMode(_ result: @escaping CHResult<UInt8>) {}
    func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) {}
    /// `acknowledged` is reported only by kinds whose empty list can ACK without FIRST/LAST.
    func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) {}
    func rename(_ id: String, _ name: String, _ result: @escaping CHResult<CHEmpty>) { result(.failure(BleError.unsupported)) }
    func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) {}
    func add(_ id: Data, _ name: String, _ result: @escaping CHResult<CHEmpty>) { result(.failure(BleError.unsupported)) }
    func batchAdd(_ data: Data, progress: @escaping (Int, Int) -> Void, _ result: @escaping CHResult<CHEmpty>) { result(.failure(BleError.unsupported)) }
}

private func listResult(_ acknowledged: (() -> Void)?, _ failed: @escaping () -> Void) -> CHResult<CHEmpty> {
    { result in
        switch result {
        case .success: acknowledged?()
        case .failure: failed()
        }
    }
}

private final class CardChannel: CredentialChannel, CHCardDelegate {
    private let capable: CHCardCapable
    init(_ capable: CHCardCapable) { self.capable = capable }
    override func attach(_ events: CredentialEvents) { super.attach(events); capable.registerEventDelegate(self) }
    override func detach() { capable.unregisterEventDelegate(self) }
    override func readMode(_ result: @escaping CHResult<UInt8>) { capable.cardsModeGet(result: result) }
    override func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) { capable.cardsModeSet(mode: mode, result: result) }
    override func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) { capable.cards(result: listResult(acknowledged, failed)) }
    override func rename(_ id: String, _ name: String, _ result: @escaping CHResult<CHEmpty>) { capable.cardsChange(ID: id, hexName: name, result: result) }
    override func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) { capable.cardDelete(ID: id, result: result) }
    override func add(_ id: Data, _ name: String, _ result: @escaping CHResult<CHEmpty>) { capable.cardAdd(id: id, hexName: name, result: result) }
    override func batchAdd(_ data: Data, progress: @escaping (Int, Int) -> Void, _ result: @escaping CHResult<CHEmpty>) {
        capable.cardBatchAdd(data: data, progressCallback: progress, result: result)
    }

    func onCardReceiveStart(device: CHSesameConnector) { events?.started() }
    func onCardReceiveEnd(device: CHSesameConnector) { events?.ended() }
    func onCardReceive(device: CHSesameConnector, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: false) }
    func onCardChanged(device: CHSesameConnector, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: true) }
    func onCardModeChanged(mode: UInt8) { events?.modeChanged(mode) }
    func onCardDelete(device: CHSesameConnector, id: String) { events?.deleted(id) }
}

private final class FingerPrintChannel: CredentialChannel, CHFingerPrintDelegate {
    private let capable: CHFingerPrintCapable
    init(_ capable: CHFingerPrintCapable) { self.capable = capable }
    override var idleMode: UInt8 { 2 }
    override func attach(_ events: CredentialEvents) { super.attach(events); capable.registerEventDelegate(self) }
    override func detach() { capable.unregisterEventDelegate(self) }
    override func readMode(_ result: @escaping CHResult<UInt8>) { capable.fingerPrintModeGet(result: result) }
    override func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) { capable.fingerPrintModeSet(mode: mode, result: result) }
    override func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) { capable.fingerPrints(result: listResult(nil, failed)) }
    override func rename(_ id: String, _ name: String, _ result: @escaping CHResult<CHEmpty>) { capable.fingerPrintsChange(ID: id, hexName: name, result: result) }
    override func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) { capable.fingerPrintDelete(ID: id, result: result) }

    func onFingerPrintReceiveStart(device: CHDevice) { events?.started() }
    func onFingerPrintReceiveEnd(device: CHDevice) { events?.ended() }
    func onFingerPrintReceive(device: CHDevice, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: false) }
    func onFingerPrintChanged(device: CHDevice, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: true) }
    func onFingerModeChange(mode: UInt8) { events?.modeChanged(mode) }
    func onFingerPrintDelete(device: CHDevice, id: String) { events?.deleted(id) }
}

private final class PassCodeChannel: CredentialChannel, CHPassCodeDelegate {
    private let capable: CHPassCodeCapable
    init(_ capable: CHPassCodeCapable) { self.capable = capable }
    override func attach(_ events: CredentialEvents) { super.attach(events); capable.registerEventDelegate(self) }
    override func detach() { capable.unregisterEventDelegate(self) }
    override func readMode(_ result: @escaping CHResult<UInt8>) { capable.passCodeModeGet(result: result) }
    override func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) { capable.passCodeModeSet(mode: mode, result: result) }
    override func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) { capable.passCodes(result: listResult(acknowledged, failed)) }
    override func rename(_ id: String, _ name: String, _ result: @escaping CHResult<CHEmpty>) { capable.passCodeChange(ID: id, hexName: name, result: result) }
    override func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) { capable.passCodeDelete(ID: id, result: result) }
    override func add(_ id: Data, _ name: String, _ result: @escaping CHResult<CHEmpty>) { capable.passCodeAdd(id: id, hexName: name, result: result) }
    override func batchAdd(_ data: Data, progress: @escaping (Int, Int) -> Void, _ result: @escaping CHResult<CHEmpty>) {
        capable.passCodeBatchAdd(data: data, progressCallback: progress, result: result)
    }

    func onPassCodeReceiveStart(device: CHSesameConnector) { events?.started() }
    func onPassCodeReceiveEnd(device: CHSesameConnector) { events?.ended() }
    func onPassCodeReceive(device: CHSesameConnector, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: false) }
    func onPassCodeChanged(device: CHSesameConnector, id: String, hexName: String, type: UInt8) { events?.received(id, name: hexName, type: type, changed: true) }
    func onPassCodeModeChanged(mode: UInt8) { events?.modeChanged(mode) }
    func onPassCodeDelete(device: CHSesameConnector, id: String) { events?.deleted(id) }
}

private final class FaceChannel: CredentialChannel, CHFaceDelegate {
    private let capable: CHFaceCapable
    init(_ capable: CHFaceCapable) { self.capable = capable }
    override var deleteConfirmedByEvent: Bool { true }
    override func attach(_ events: CredentialEvents) { super.attach(events); capable.registerEventDelegate(self) }
    override func detach() { capable.unregisterEventDelegate(self) }
    override func readMode(_ result: @escaping CHResult<UInt8>) { capable.faceModeGet(result: result) }
    override func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) { capable.faceModeSet(mode: mode, result: result) }
    override func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) { capable.faces(result: listResult(nil, failed)) }
    override func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) { capable.faceDelete(ID: id, result: result) }

    func onFaceReceiveStart(device: CHSesameConnector) { events?.started() }
    func onFaceReceiveEnd(device: CHSesameConnector) { events?.ended() }
    func onFaceReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) { events?.received(id, name: name, type: type, changed: false) }
    func onFaceChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) { events?.received(id, name: name, type: type, changed: true) }
    func onFaceModeChanged(mode: UInt8) { events?.modeChanged(mode) }
    func onFaceDeleted(faceId: UInt8, isSuccess: Bool) { isSuccess ? events?.deleted(String(format: "%02x", faceId)) : events?.deleteFailed() }
}

private final class PalmChannel: CredentialChannel, CHPalmDelegate {
    private let capable: CHPalmCapable
    init(_ capable: CHPalmCapable) { self.capable = capable }
    override var deleteConfirmedByEvent: Bool { true }
    override func attach(_ events: CredentialEvents) { super.attach(events); capable.registerEventDelegate(self) }
    override func detach() { capable.unregisterEventDelegate(self) }
    override func readMode(_ result: @escaping CHResult<UInt8>) { capable.palmModeGet(result: result) }
    override func setMode(_ mode: UInt8, _ result: @escaping CHResult<CHEmpty>) { capable.palmModeSet(mode: mode, result: result) }
    override func requestList(acknowledged: @escaping () -> Void, failed: @escaping () -> Void) { capable.palms(result: listResult(nil, failed)) }
    override func delete(_ id: String, _ result: @escaping CHResult<CHEmpty>) { capable.palmDelete(ID: id, result: result) }

    func onPalmReceiveStart(device: CHSesameConnector) { events?.started() }
    func onPalmReceiveEnd(device: CHSesameConnector) { events?.ended() }
    func onPalmReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) { events?.received(id, name: name, type: type, changed: false) }
    func onPalmChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) { events?.received(id, name: name, type: type, changed: true) }
    func onPalmModeChanged(mode: UInt8) { events?.modeChanged(mode) }
    func onPalmDeleted(palmId: UInt8, isSuccess: Bool) { isSuccess ? events?.deleted(String(format: "%02x", palmId)) : events?.deleteFailed() }
}
