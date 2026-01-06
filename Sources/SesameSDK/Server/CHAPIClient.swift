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

class CustomHeaderInterceptor: NSObject, AWSNetworkingRequestInterceptorProtocol {
    func interceptRequest(_ request: NSMutableURLRequest!) -> AWSTask<AnyObject>! {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CHConfiguration.shared.region(),
                                                                identityPoolId: CHConfiguration.shared.clientId)
        return credentialsProvider.getIdentityId().continueWith { task -> AnyObject in
            if let identifyId = task.result as? String {
                request.setValue(identifyId, forHTTPHeaderField: "AppIdentifyID")
            }
            return request
        }
    }
}

public class CHAPIClient {
    private static var _shared: CHAPIClient?
    public let apiGatewayClient: AWSAPIGatewayClient = AWSAPIGatewayClient()

    public static var shared: CHAPIClient {
        guard let instance = _shared else {
            fatalError("CHAccountManager.shared 尚未初始化。请先调用 CHAccountManager.initialize(credentialsProvider:) 进行初始化")
        }
        return instance
    }
    
    /// - Parameters:
    ///   - credentialsProvider: AWS 凭证提供者（必须）
    ///   - region: AWS 区域（默认 APNortheast1）
    ///   - apiKey: API Gateway API Key（可选，默认使用 CHConfiguration）
    ///   - baseUrl: API Gateway 基础 URL（可选，默认使用环境配置）
    public static func initialize(credentialsProvider: AWSCredentialsProvider,
                                  region: AWSRegionType = .APNortheast1,
                                  apiKey: String? = nil,
                                  baseUrl: String? = nil) {
        guard _shared == nil else {
            print("⚠️ CHAccountManager 已经初始化，忽略重复初始化")
            return
        }
        _shared = CHAPIClient(
            credentialsProvider: credentialsProvider,
            region: region,
            apiKey: apiKey,
            baseUrl: baseUrl
        )
    }
    
    /// 使用自定义凭证提供商初始化
    /// - Parameters:
    ///   - credentialsProvider: AWS 凭证提供者（必须）
    ///   - region: AWS 区域（默认 APNortheast1）
    ///   - apiKey: API Gateway API Key（可选，默认使用 CHConfiguration）
    ///   - baseUrl: API Gateway 基础 URL（可选，默认使用环境配置）
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
