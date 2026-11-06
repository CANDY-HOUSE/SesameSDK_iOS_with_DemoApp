import Amplify
import AWSAPIPlugin
import AWSCognitoAuthPlugin
import Foundation

/// REST access for system entry points (Siri, Watch) that run without the web UI: devices behind a WM2 / Hub3,
/// and on the Watch also guest-key signing, history and battery upload.
/// Requests are signed with the Cognito identity pool credentials (AWS_IAM) and carry the API key, as in the native app.
public enum SesameGateway {
    public struct API {
        public let endpoint: String
        public let region: String
        public let apiKey: String
        public let appIdentifyId: String

        public init(endpoint: String, region: String, apiKey: String, appIdentifyId: String) {
            self.endpoint = endpoint
            self.region = region
            self.apiKey = apiKey
            self.appIdentifyId = appIdentifyId
        }
    }

    public struct Shadow {
        /// At least one WM2 / Hub3 reports the device as connected.
        public let gatewayOnline: Bool
        public let mechStatus: Data?
        public let batteryPercentage: Int?
    }

    public enum GatewayError: Error {
        case notConfigured, invalidKey, invalidResponse
    }

    private static let apiName = "sesameGateway"
    private static var api: API?

    /// Amplify can be configured only once per process, so the host's Auth setup also goes through here.
    /// Without `api` only the Auth plugin is added and gateway requests fail with `notConfigured`.
    public static func configure(auth: [String: Any], api: API?) throws {
        var configuration: [String: Any] = ["auth": ["plugins": ["awsCognitoAuthPlugin": auth]]]
        if let api {
            configuration["api"] = ["plugins": ["awsAPIPlugin": [apiName: [
                "endpointType": "REST",
                "endpoint": api.endpoint,
                "region": api.region,
                "authorizationType": "AWS_IAM"
            ]]]]
        }
        let decoded = try JSONDecoder().decode(AmplifyConfiguration.self, from: JSONSerialization.data(withJSONObject: configuration))
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        if api != nil { try Amplify.add(plugin: AWSAPIPlugin()) }
        try Amplify.configure(decoded)
        self.api = api
    }

    public static func shadow(deviceId: UUID) async throws -> Shadow {
        let data = try await Amplify.API.get(request: request("/device/v1/sesame2/\(deviceId.uuidString)", body: nil))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw GatewayError.invalidResponse }
        let gateways = json["wm2s"] as? [String: String] ?? [:]
        return Shadow(
            gatewayOnline: gateways.values.contains { $0 != "00" },
            mechStatus: (json["mechst"] as? String).flatMap(Data.init(hex:)),
            batteryPercentage: json["batteryPercentage"] as? Int
        )
    }

    /// Sends one item code (lock 82, unlock 83, toggle 88, click 89, …) through the device's gateway.
    /// `history` is the tag recorded by the device; the hex `secretKey` signs the request time as the firmware expects.
    public static func send(command: UInt8, deviceId: UUID, secretKey: String, history: Data) async throws {
        guard let secretKey = Data(hex: secretKey), secretKey.count == 16 else { throw GatewayError.invalidKey }
        let timestamp = withUnsafeBytes(of: UInt32(Date().timeIntervalSince1970).littleEndian) { Data($0) }
        let sign = CMAC.aes(timestamp.subdata(in: 1..<4), key: secretKey).prefix(4)
        let body = try JSONSerialization.data(withJSONObject: [
            "cmd": Int(command),
            "history": history.base64EncodedString(),
            "sign": sign.map { String(format: "%02x", $0) }.joined()
        ])
        _ = try await Amplify.API.post(request: request("/device/v1/iot/sesame2/\(deviceId.uuidString)", body: body))
    }

    /// Restricted (guest) keys log in with a token the server signs. `guestKeyId` is the key's `secretKey` field,
    /// which for guest keys only identifies the key; the real secret stays on the server.
    public static func sign(deviceId: UUID, token: String, guestKeyId: String) async throws -> String {
        let body = try JSONSerialization.data(withJSONObject: ["deviceId": deviceId.uuidString, "token": token, "secretKey": guestKeyId])
        let data = try await Amplify.API.post(request: request("/device/v1/sesame2/sign", body: body))
        guard let signed = String(data: data, encoding: .utf8), !signed.isEmpty else { throw GatewayError.invalidResponse }
        return signed
    }

    /// Uploads one history record read over Bluetooth; OS3 records are marked with type 5, as in the native app.
    public static func postHistory(deviceId: UUID, historyHex: String, os3: Bool) async throws {
        var json: [String: Any] = ["s": deviceId.uuidString, "v": historyHex]
        if os3 { json["t"] = "5" }
        _ = try await Amplify.API.post(request: request("/device/v1/sesame2/historys", body: JSONSerialization.data(withJSONObject: json)))
    }

    /// Uploads the battery voltage read over Bluetooth; the server records it and returns the percentage.
    public static func battery(deviceId: UUID, payload: String) async throws -> Int {
        let body = try JSONSerialization.data(withJSONObject: ["payload": payload])
        let data = try await Amplify.API.post(request: request("/device/v1/sesame5/\(deviceId.uuidString)/battery", body: body))
        guard let percentage = (try JSONSerialization.jsonObject(with: data) as? [String: Any])?["batteryPercentage"] as? Int else {
            throw GatewayError.invalidResponse
        }
        return percentage
    }

    private static func request(_ path: String, body: Data?) throws -> RESTRequest {
        guard let api else { throw GatewayError.notConfigured }
        return RESTRequest(
            apiName: apiName,
            path: path,
            headers: ["Content-Type": "application/json", "x-api-key": api.apiKey, "AppIdentifyID": api.appIdentifyId],
            body: body
        )
    }
}

private extension Data {
    init?(hex: String) {
        guard hex.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self.init(bytes)
    }
}
