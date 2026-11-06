import Foundation

public enum CHBleSupport {
    public private(set) static var host: CHBleHost!
    public private(set) static var keys: CHKeyPersistence!
    public private(set) static var gatewayTenantId = ""

    public static func initialize(host: CHBleHost, keys: CHKeyPersistence, gatewayTenantId: String) {
        self.host = host
        self.keys = keys
        self.gatewayTenantId = gatewayTenantId
    }
}

public protocol CHBleHost: AnyObject {
    func isNetworkAvailable() -> Bool
    func shouldUploadHistory(deviceId: UUID) -> Bool
    func signGuestKey(deviceId: UUID, token: String, secretKey: String, result: @escaping CHResult<String>)
    func postFirmwareVersion(deviceId: UUID, versionTag: String, result: @escaping CHResult<CHEmpty>)
    func postHistory(deviceId: UUID, historyHex: String, os3: Bool, result: @escaping CHResult<CHEmpty>)
    func postBatteryData(deviceId: UUID, payload: String, result: @escaping CHResult<Int>)
    func registerOs2(deviceId: UUID, appKey: String, nonce: String, registrationKey: String, productType: String, result: @escaping CHResult<CHRegistrationResult>)
    func registerOs3(deviceId: UUID, productType: Int, publicKey: String, result: @escaping CHResult<CHEmpty>)
}

public struct CHRegistrationResult {
    public let signature: String
    public let token: String
    public let publicKey: String

    public init(signature: String, token: String, publicKey: String) {
        self.signature = signature
        self.token = token
        self.publicKey = publicKey
    }
}

public protocol CHKeyPersistence: AnyObject {
    func save(_ key: CHDeviceKey)
    func delete(deviceId: UUID)
}
