import Amplify
import AWSCognitoAuthPlugin
import Foundation
import SesameGateway
import SesameSDK
import UIKit

enum LegacySession {
    private static let retiredKey = "webSessionRetired"
    /// Same flag the previous native app wrote, so an upgrade does not look like a fresh install.
    private static let installedKey = "HasInstalled"
    private static let appIdentifyKey = "co.candyhouse.sesame2.AppIdentifyID"

    static var retired: Bool { UserDefaults.standard.bool(forKey: retiredKey) }

    @MainActor
    static func prepareInstall() {
        guard !UserDefaults.standard.bool(forKey: installedKey), UIApplication.shared.isProtectedDataAvailable else { return }
        do {
            try clearAuthKeychain()
            KeyStore.shared.removeAll()
            UserDefaults.standard.set(true, forKey: installedKey)
        } catch {}
    }

    @MainActor
    static func token() async throws -> String? {
        prepareInstall()
        if retired { return nil }
        try configure()
        let session = try await Amplify.Auth.fetchAuthSession()
        guard !retired, session.isSignedIn else { return nil }
        guard let provider = session as? AWSAuthCognitoSession else { throw SessionError.unavailable }
        return try provider.getCognitoTokens().get().idToken
    }

    static func retire() async {
        UserDefaults.standard.set(true, forKey: retiredKey)
        guard (try? configure()) != nil else { return }
        _ = await Amplify.Auth.signOut()
    }

    static func guestIdentityId() -> String {
        if let existing = CHKeychain.string(forKey: appIdentifyKey), !existing.isEmpty { return existing }
        let id = "ap-northeast-1:" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        CHKeychain.setString(id, forKey: appIdentifyKey)
        return id
    }

    private static let configuration: Result<Void, Error> = Result {
        try SesameGateway.configure(auth: try authPluginConfiguration(), api: gatewayAPI())
    }

    /// Siri uses the gateway with the same Cognito identity, so Amplify is set up once for both.
    static func configure() throws {
        try configuration.get()
    }

    private static func legacyConfiguration() throws -> [String: Any] {
        guard let url = Bundle.main.url(forResource: "awsconfiguration", withExtension: "json"),
              let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else {
            throw SessionError.configuration
        }
        return json
    }

    private static func authPluginConfiguration() throws -> [String: Any] {
        let legacy = try legacyConfiguration()
        return legacy.filter { ["IdentityManager", "CredentialsProvider", "CognitoUserPool", "Auth"].contains($0.key) }
    }

    /// `sesamegateway.json` holds the API key and is not published with the open-source sync.
    private static func gatewayAPI() -> SesameGateway.API? {
        guard let url = Bundle.main.url(forResource: "sesamegateway", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let region = json["region"] as? String, let apiKey = json["apiKey"] as? String,
              let endpoint = json[AppConfig.buildType == "debug" ? "debugEndpoint" : "releaseEndpoint"] as? String else { return nil }
        return SesameGateway.API(endpoint: endpoint, region: region, apiKey: apiKey, appIdentifyId: guestIdentityId())
    }

    static func identityPoolId() -> String? {
        guard let provider = (try? legacyConfiguration())?["CredentialsProvider"] as? [String: Any],
              let identity = provider["CognitoIdentity"] as? [String: Any],
              let defaults = identity["Default"] as? [String: Any] else { return nil }
        return defaults["PoolId"] as? String
    }

    private static func clearAuthKeychain() throws {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, let identityPoolId = identityPoolId() else {
            throw SessionError.configuration
        }
        let legacyIdentityPoolIds = ["ap-northeast-1:33a5a21f-3c79-439f-98a9-9fdbbff04e19"]
        let services = [
            "com.amplify.awsCognitoAuthPlugin",
            "Optional(\"\(bundleIdentifier)\").AWSMobileClient",
            "\(bundleIdentifier).AWSCognitoIdentityUserPool"
        ] + ([identityPoolId] + legacyIdentityPoolIds).map { "\(bundleIdentifier).AWSCognitoCredentialsProvider.\($0)" }
        for service in services {
            let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service] as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        }
    }

    enum SessionError: Error {
        case configuration, unavailable
    }
}
