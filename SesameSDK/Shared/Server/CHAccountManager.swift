//
//  AccountManager.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//
/**
 API Gateway ID : jhcr1i3ecb
 API Gateway desc : " app 不需要登入的 API"
 */

#if os(iOS)
import AWSCore
import AWSAPIGateway
import AWSIoT
#endif
import Foundation

#if DEBUG
let awsApiGatewayBaseUrl = "https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/dev"
#else
let awsApiGatewayBaseUrl = "https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod"
#endif

public class CHAccountManager {
    public static let shared: CHAccountManager! = CHAccountManager()
    let apiGatewayClient: AWSAPIGatewayClient = AWSAPIGatewayClient()
    
    init() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CHConfiguration.shared.region(),
                                                                identityPoolId: CHConfiguration.shared.clientId)
        let serviceConfiguration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)
        let signer = AWSSignatureV4Signer(
              credentialsProvider: credentialsProvider,
              endpoint: AWSEndpoint(region: .APNortheast1,
                                    service: .APIGateway,
                                    url: NSURL.fileURL(withPath: awsApiGatewayBaseUrl)))
        apiGatewayClient.configuration = serviceConfiguration!
        apiGatewayClient.configuration.requestInterceptors = [AWSNetworkingRequestInterceptor(), signer] as? [AWSNetworkingRequestInterceptorProtocol]
        apiGatewayClient.apiKey = CHConfiguration.shared.apiKey
        apiGatewayClient.configuration.baseURL = URL(string: awsApiGatewayBaseUrl)
    }
}
