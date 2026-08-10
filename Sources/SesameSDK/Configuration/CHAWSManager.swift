import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSPluginsCore
import Foundation

public enum UserState: String {
    case unknown
    case signedIn
    case signedOut
}

public enum SignInState {
    case customChallenge
    case signedIn
    case unknown
}

public struct SignUpResult {
    public let isSignUpComplete: Bool
    public let destination: String?
}

public enum CHAuthError: LocalizedError {
    case usernameExists(String)
    case notAuthorized(String)
    case invalidState(String)
    case service(String, Error?)

    public var errorDescription: String? {
        switch self {
        case .usernameExists(let message),
             .notAuthorized(let message),
             .invalidState(let message),
             .service(let message, _):
            return message
        }
    }

    static func wrap(_ error: Error) -> CHAuthError {
        if let error = error as? CHAuthError {
            return error
        }
        if let authError = error as? AuthError {
            if let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
               case .usernameExists = cognitoError {
                return .usernameExists(authError.errorDescription)
            }
            switch authError {
            case .notAuthorized:
                return .notAuthorized(authError.errorDescription)
            case .invalidState:
                return .invalidState(authError.errorDescription)
            default:
                return .service(authError.errorDescription, authError.underlyingError)
            }
        }
        return .service(error.localizedDescription, error)
    }
}

public final class CHAWSManager {
    public static let apiName = "sesameAPI"

    private enum ConfigurationState {
        case notConfigured
        case configuring
        case configured
        case failed(Error)
    }

    private final class Listener {
        weak var owner: AnyObject?
        let callback: (UserState) -> Void

        init(owner: AnyObject, callback: @escaping (UserState) -> Void) {
            self.owner = owner
            self.callback = callback
        }
    }

    private static let lock = NSLock()
    private static let configurationCondition = NSCondition()
    private static var configurationState = ConfigurationState.notConfigured
    private static var listeners: [ObjectIdentifier: Listener] = [:]
    private static var hubToken: UnsubscribeToken?
    private static var state: UserState = .unknown

    public static var currentUserState: UserState {
        lock.chWithLock { state }
    }

    public static var isSignedIn: Bool {
        currentUserState == .signedIn
    }

    public static func configure(bundle: Bundle = .main) throws {
        configurationCondition.lock()
        while case .configuring = configurationState {
            configurationCondition.wait()
        }
        switch configurationState {
        case .configured:
            configurationCondition.unlock()
            return
        case .failed(let error):
            configurationCondition.unlock()
            throw error
        case .notConfigured:
            configurationState = .configuring
            configurationCondition.unlock()
        case .configuring:
            configurationCondition.unlock()
            return
        }

        do {
            guard let url = bundle.url(forResource: "awsconfiguration", withExtension: "json") else {
                throw CHAuthError.service("Missing awsconfiguration.json in the current target.", nil)
            }
            let legacyData = try Data(contentsOf: url)
            guard let legacy = try JSONSerialization.jsonObject(with: legacyData) as? [String: Any] else {
                throw CHAuthError.service("Invalid awsconfiguration.json.", nil)
            }

            var authPlugin: [String: Any] = [:]
            for key in ["IdentityManager", "CredentialsProvider", "CognitoUserPool", "Auth"] {
                if let value = legacy[key] {
                    authPlugin[key] = value
                }
            }

            let configurationObject: [String: Any] = [
                "auth": [
                    "plugins": [
                        "awsCognitoAuthPlugin": authPlugin
                    ]
                ],
                "api": [
                    "plugins": [
                        "awsAPIPlugin": [
                            apiName: [
                                "endpointType": "REST",
                                "endpoint": awsApiGatewayBaseUrl,
                                "region": CHConfiguration.shared.regionName,
                                "authorizationType": "AWS_IAM"
                            ]
                        ]
                    ]
                ]
            ]
            let configurationData = try JSONSerialization.data(withJSONObject: configurationObject)
            let configuration = try JSONDecoder().decode(AmplifyConfiguration.self, from: configurationData)

            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(configuration)

            hubToken = Amplify.Hub.listen(to: .auth) { payload in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    updateState(.signedIn)
                case HubPayload.EventName.Auth.signedOut,
                     HubPayload.EventName.Auth.sessionExpired,
                     HubPayload.EventName.Auth.userDeleted:
                    updateState(.signedOut)
                default:
                    break
                }
            }
            configurationCondition.lock()
            configurationState = .configured
            configurationCondition.broadcast()
            configurationCondition.unlock()
        } catch {
            configurationCondition.lock()
            configurationState = .failed(error)
            configurationCondition.broadcast()
            configurationCondition.unlock()
            throw error
        }
    }

    public static func initialize(bundle: Bundle = .main, completion: @escaping (UserState, Error?) -> Void) {
        do {
            try configure(bundle: bundle)
        } catch {
            completion(.unknown, error)
            return
        }

        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                let newState: UserState = session.isSignedIn ? .signedIn : .signedOut
                lock.chWithLock { state = newState }
                completion(newState, nil)
            } catch {
                lock.chWithLock { state = .signedOut }
                completion(.signedOut, error)
            }
        }
    }

    public static func addUserStateListener(
        _ owner: AnyObject,
        callback: @escaping (UserState) -> Void
    ) {
        lock.chWithLock {
            listeners[ObjectIdentifier(owner)] = Listener(owner: owner, callback: callback)
        }
    }

    public static func removeUserStateListener(_ owner: AnyObject) {
        lock.chWithLock {
            listeners.removeValue(forKey: ObjectIdentifier(owner))
        }
    }

    public static func signUp(
        username: String,
        password: String,
        attributes: [String: String],
        completion: @escaping (SignUpResult?, Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                let userAttributes = attributes.map {
                    AuthUserAttribute(AuthUserAttributeKey(rawValue: $0.key), value: $0.value)
                }
                let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
                let result = try await Amplify.Auth.signUp(
                    username: username,
                    password: password,
                    options: options
                )
                let destination: String?
                switch result.nextStep {
                case .confirmUser(let deliveryDetails, _, _):
                    destination = deliveryDetails.flatMap { destinationString($0.destination) }
                default:
                    destination = nil
                }
                completion(SignUpResult(isSignUpComplete: result.isSignUpComplete, destination: destination), nil)
            } catch {
                completion(nil, CHAuthError.wrap(error))
            }
        }
    }

    public static func confirmSignUp(
        username: String,
        code: String,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                _ = try await Amplify.Auth.confirmSignUp(for: username, confirmationCode: code)
                completion(nil)
            } catch {
                completion(CHAuthError.wrap(error))
            }
        }
    }

    public static func resendSignUpCode(
        username: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                let result = try await Amplify.Auth.resendSignUpCode(for: username)
                completion(destinationString(result.destination), nil)
            } catch {
                completion(nil, CHAuthError.wrap(error))
            }
        }
    }

    public static func signIn(
        username: String,
        password: String,
        completion: @escaping (SignInState?, Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                let result = try await Amplify.Auth.signIn(username: username, password: password)
                completion(mapSignInStep(result.nextStep), nil)
            } catch {
                completion(nil, CHAuthError.wrap(error))
            }
        }
    }

    public static func confirmSignIn(
        challengeResponse: String,
        completion: @escaping (SignInState?, Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                let result = try await Amplify.Auth.confirmSignIn(challengeResponse: challengeResponse)
                completion(mapSignInStep(result.nextStep), nil)
            } catch {
                completion(nil, CHAuthError.wrap(error))
            }
        }
    }

    public static func signOut(completion: (() -> Void)? = nil) {
        Task {
            try? configure()
            _ = await Amplify.Auth.signOut()
            updateState(.signedOut)
            completion?()
        }
    }

    public static func fetchUserAttributes(
        completion: @escaping (Result<[String: String], Error>) -> Void
    ) {
        Task {
            do {
                try configure()
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                let values = Dictionary(uniqueKeysWithValues: attributes.map { ($0.key.rawValue, $0.value) })
                completion(.success(values))
            } catch {
                completion(.failure(CHAuthError.wrap(error)))
            }
        }
    }

    public static func updateUserAttribute(
        key: String,
        value: String,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                try configure()
                let attribute = AuthUserAttribute(AuthUserAttributeKey(rawValue: key), value: value)
                _ = try await Amplify.Auth.update(userAttribute: attribute)
                completion(nil)
            } catch {
                completion(CHAuthError.wrap(error))
            }
        }
    }

    public static func userSub(completion: @escaping (String?) -> Void) {
        Task {
            do {
                try configure()
                let user = try await Amplify.Auth.getCurrentUser()
                completion(user.userId)
            } catch {
                completion(nil)
            }
        }
    }

    public static func idToken(completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                try configure()
                let session = try await Amplify.Auth.fetchAuthSession()
                guard let provider = session as? AuthCognitoTokensProvider else {
                    throw CHAuthError.service("Cognito tokens are unavailable.", nil)
                }
                completion(.success(try provider.getCognitoTokens().get().idToken))
            } catch {
                completion(.failure(CHAuthError.wrap(error)))
            }
        }
    }

    private static func mapSignInStep(_ step: AuthSignInStep) -> SignInState {
        switch step {
        case .done:
            updateState(.signedIn)
            return .signedIn
        case .confirmSignInWithCustomChallenge:
            return .customChallenge
        default:
            return .unknown
        }
    }

    private static func updateState(_ newState: UserState) {
        let callbacks: [(UserState) -> Void] = lock.chWithLock {
            guard state != newState else { return [] }
            state = newState
            listeners = listeners.filter { $0.value.owner != nil }
            return listeners.values.map(\.callback)
        }
        callbacks.forEach { $0(newState) }
    }

    private static func destinationString(_ destination: DeliveryDestination) -> String? {
        switch destination {
        case .email(let value), .phone(let value), .sms(let value), .unknown(let value):
            return value
        }
    }
}

private extension NSLock {
    func chWithLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
