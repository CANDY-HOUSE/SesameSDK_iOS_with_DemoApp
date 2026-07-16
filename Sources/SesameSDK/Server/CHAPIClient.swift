//
//  AccountManager.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

#if os(iOS)
import AWSCore
import AWSAPIGateway
import AWSIoT
#endif
import Foundation

#if DEBUG
let awsApiGatewayBaseUrl = "https://app.candyhouse.co/dev"
#else
let awsApiGatewayBaseUrl = "https://app.candyhouse.co/prod"
#endif

enum CHAppIdentify {
    private static let keyTag = "co.candyhouse.sesame2.AppIdentifyID"
    static let current: String = {
        if let existing = CHKeychain.string(forKey: keyTag), !existing.isEmpty {
            return existing
        }
        let id = generate()
        CHKeychain.setString(id, forKey: keyTag)
        return id
    }()

    private static func generate() -> String {
        let region = CHConfiguration.shared.clientId.split(separator: ":").first.map(String.init) ?? "ap-northeast-1"
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "\(region):\(hex)"
    }
}

class CustomHeaderInterceptor: NSObject, AWSNetworkingRequestInterceptorProtocol {
    func interceptRequest(_ request: NSMutableURLRequest!) -> AWSTask<AnyObject>! {
        request.setValue(CHAppIdentify.current, forHTTPHeaderField: "AppIdentifyID")
        return AWSTask(result: request)
    }
}

public class CHAPIClient {
    private static var _shared: CHAPIClient?
    public let apiGatewayClient: AWSAPIGatewayClient = AWSAPIGatewayClient()
    static let defaultCredentialsProvider = AWSCognitoCredentialsProvider(
        regionType: CHConfiguration.shared.region(),
        identityPoolId: CHConfiguration.shared.clientId
    )

    public static var shared: CHAPIClient {
        if _shared == nil {
            _shared = CHAPIClient(credentialsProvider: defaultCredentialsProvider)
        }
        return _shared!
    }
    
    @discardableResult
    public static func initialize(credentialsProvider: AWSCredentialsProvider? = nil,
                                  region: AWSRegionType = .APNortheast1,
                                  apiKey: String? = nil,
                                  baseUrl: String? = nil) -> CHAPIClient {
        guard _shared == nil else {
            return _shared!
        }
        _shared = CHAPIClient(
            credentialsProvider: credentialsProvider ?? defaultCredentialsProvider,
            region: region,
            apiKey: apiKey,
            baseUrl: baseUrl
        )
        return _shared!
    }
    
    public init(credentialsProvider: AWSCredentialsProvider,
                region: AWSRegionType = .APNortheast1,
                apiKey: String? = nil,
                baseUrl: String? = nil) {
        let serviceConfiguration = AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider)
        let apiBaseUrl = baseUrl ?? awsApiGatewayBaseUrl
        let signer = AWSSignatureV4Signer(
              credentialsProvider: credentialsProvider,
              endpoint: AWSEndpoint(region: region,
                                    service: .APIGateway,
                                    url: NSURL.fileURL(withPath: apiBaseUrl)))
        
        apiGatewayClient.configuration = serviceConfiguration!
        apiGatewayClient.configuration.requestInterceptors = [CustomHeaderInterceptor(), AWSNetworkingRequestInterceptor(), signer] as? [AWSNetworkingRequestInterceptorProtocol]
        apiGatewayClient.apiKey = apiKey ?? CHConfiguration.shared.apiKey
        apiGatewayClient.configuration.baseURL = URL(string: apiBaseUrl)
    }
}
