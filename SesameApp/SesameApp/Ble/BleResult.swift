import Foundation
import SesameSDK

enum BleError: Error {
    case unavailable, unsupported, invalid, timeout
}

private final class Once {
    private let lock = NSLock()
    private var done = false

    func run(_ body: () -> Void) {
        lock.lock()
        let first = !done
        done = true
        lock.unlock()
        if first { body() }
    }
}

/// Awaits one SDK callback; the SDK may never answer a dropped command, so callers pass a timeout.
@MainActor
func bleResult<T>(timeout: TimeInterval? = nil, _ call: (@escaping CHResult<T>) -> Void) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        let once = Once()
        call { result in once.run { continuation.resume(with: result.map(\.data)) } }
        if let timeout {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                once.run { continuation.resume(throwing: BleError.timeout) }
            }
        }
    }
}

func require(_ condition: Bool) throws {
    if !condition { throw BleError.invalid }
}

extension CHDevice {
    var uuid: String { deviceId.uuidString.uppercased() }
    var loggedIn: Bool { deviceStatus.loginStatus == .logined }
}

extension Int8 {
    var txPowerByte: UInt8 { UInt8(bitPattern: self) }
}
