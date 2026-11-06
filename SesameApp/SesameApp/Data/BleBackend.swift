import Foundation
import Network
import SesameSDK

final class BleBackend: CHBleHost {
    typealias CloudRequest = (_ operation: String, _ body: [String: Any], _ deviceUUID: String?) async throws -> Any?

    static let shared = BleBackend()

    @MainActor var requestCloud: CloudRequest?
    private let lock = NSLock()
    private var gateways: Set<String> = []
    private let monitor = NWPathMonitor()
    private var networkAvailable = true
    private(set) var networkType = "unknown"

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.networkAvailable = path.status == .satisfied
            self?.networkType = path.status != .satisfied ? "none" : path.usesInterfaceType(.cellular) ? "cellular" : "wifi"
        }
        monitor.start(queue: DispatchQueue(label: "BleBackend.network"))
    }

    func isNetworkAvailable() -> Bool {
        networkAvailable
    }

    var gatewayDevices: Set<String> {
        get { lock.lock(); defer { lock.unlock() }; return gateways }
        set { lock.lock(); gateways = newValue; lock.unlock() }
    }

    func shouldUploadHistory(deviceId: UUID) -> Bool {
        !gatewayDevices.contains(deviceId.uuidString.uppercased())
    }

    func signGuestKey(deviceId: UUID, token: String, secretKey: String, result: @escaping CHResult<String>) {
        request("signGuestKey", ["deviceId": deviceId.uuidString, "token": token, "secretKey": secretKey], nil, result) {
            guard let signed = $0 as? String else { throw BackendError.invalidResponse }
            return signed
        }
    }

    func postFirmwareVersion(deviceId: UUID, versionTag: String, result: @escaping CHResult<CHEmpty>) {
        request("firmware", ["versionTag": versionTag], deviceId, result) { _ in CHEmpty() }
    }

    func postHistory(deviceId: UUID, historyHex: String, os3: Bool, result: @escaping CHResult<CHEmpty>) {
        var body: [String: Any] = ["s": deviceId.uuidString, "v": historyHex]
        if os3 { body["t"] = "5" }
        request("history", body, nil, result) { _ in CHEmpty() }
    }

    func postBatteryData(deviceId: UUID, payload: String, result: @escaping CHResult<Int>) {
        request("battery", ["payload": payload], deviceId, result) {
            guard let percentage = ($0 as? [String: Any])?["batteryPercentage"] as? Int else { throw BackendError.invalidResponse }
            return percentage
        }
    }

    func registerOs2(deviceId: UUID, appKey: String, nonce: String, registrationKey: String, productType: String, result: @escaping CHResult<CHRegistrationResult>) {
        request("registerOs2", ["s1": ["ak": appKey, "n": nonce, "e": registrationKey, "t": productType]], deviceId, result) {
            guard let response = $0 as? [String: Any], let signature = response["sig1"] as? String,
                  let token = response["st"] as? String, let publicKey = response["pubkey"] as? String else {
                throw BackendError.invalidResponse
            }
            return CHRegistrationResult(signature: signature, token: token, publicKey: publicKey)
        }
    }

    func registerOs3(deviceId: UUID, productType: Int, publicKey: String, result: @escaping CHResult<CHEmpty>) {
        request("registerOs3", ["t": String(productType), "pk": publicKey], deviceId, result) { _ in CHEmpty() }
    }

    private func request<T>(_ operation: String, _ body: [String: Any], _ deviceId: UUID?, _ result: @escaping CHResult<T>, decode: @escaping (Any?) throws -> T) {
        Task { @MainActor in
            do {
                guard let transport = requestCloud else { throw BackendError.pageUnavailable }
                let value = try decode(try await transport(operation, body, deviceId?.uuidString.uppercased()))
                result(.success(CHResultStateNetworks(input: value)))
            } catch {
                result(.failure(error))
            }
        }
    }

    enum BackendError: Error {
        case pageUnavailable, invalidResponse
    }
}
