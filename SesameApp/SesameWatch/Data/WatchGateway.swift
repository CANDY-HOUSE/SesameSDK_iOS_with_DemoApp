import Foundation
import SesameGateway
import SesameSDK

/// Sets up `SesameGateway` with the guest identity of the Cognito identity pool, as the native Watch app did.
/// The configuration files are the iPhone app's (`awsconfiguration.json`, `sesamegateway.json`); without them the Watch only uses Bluetooth.
enum WatchGateway {
    /// Same Keychain key as the iPhone app; the Watch keeps its own value.
    private static let appIdentifyKey = "co.candyhouse.sesame2.AppIdentifyID"

    private static let configuration: Result<Void, Error> = Result {
        guard let api = api() else { throw SesameGateway.GatewayError.notConfigured }
        try SesameGateway.configure(auth: try json("awsconfiguration").filter {
            ["IdentityManager", "CredentialsProvider", "CognitoUserPool", "Auth"].contains($0.key)
        }, api: api)
    }

    static func configure() throws {
        try configuration.get()
    }

    private static func json(_ name: String) throws -> [String: Any] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else {
            throw SesameGateway.GatewayError.notConfigured
        }
        return json
    }

    private static func api() -> SesameGateway.API? {
#if DEBUG
        let endpointKey = "debugEndpoint"
#else
        let endpointKey = "releaseEndpoint"
#endif
        guard let json = try? json("sesamegateway"), let region = json["region"] as? String,
              let apiKey = json["apiKey"] as? String, let endpoint = json[endpointKey] as? String else { return nil }
        return SesameGateway.API(endpoint: endpoint, region: region, apiKey: apiKey, appIdentifyId: appIdentifyId())
    }

    private static func appIdentifyId() -> String {
        if let existing = CHKeychain.string(forKey: appIdentifyKey), !existing.isEmpty { return existing }
        let id = "ap-northeast-1:" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        CHKeychain.setString(id, forKey: appIdentifyKey)
        return id
    }
}
