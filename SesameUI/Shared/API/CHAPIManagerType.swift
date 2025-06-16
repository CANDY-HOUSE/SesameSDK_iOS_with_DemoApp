//
//  CHAPIManager.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
import AWSCore
import AWSAPIGateway
import SesameSDK

/// API 抽象介面
protocol CHAPIManagerType {
    associatedtype T
    static var shared: T { get }
    var apiClient: AWSAPIGatewayClient { get }
    var apiURL: String { get }
    
    func setCredentialsProvider(_ credentialsProvider :AWSCredentialsProvider)
}

/// API 設定 credential(如何從 AWS 獲取用戶憑證) 及 api 調用實作
extension CHAPIManagerType {
    func setCredentialsProvider(_ credentialsProvider :AWSCredentialsProvider) {
        let serviceConfiguration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)!
        let sesameAPISigner = signerWithURL(credentialsProvider: credentialsProvider)
        configureAPIClient(apiClient, signer: sesameAPISigner, serviceConfiguration: serviceConfiguration)
    }
    
    func signerWithURL(credentialsProvider :AWSCredentialsProvider) -> AWSSignatureV4Signer {
        let signer = AWSSignatureV4Signer(
            credentialsProvider: credentialsProvider,
            endpoint: AWSEndpoint(region: .APNortheast1,
                                  service: .APIGateway,
                                  url: NSURL.fileURL(withPath: apiURL)))
        return signer
    }
    
    func configureAPIClient(_ apiClient: AWSAPIGatewayClient, signer: AWSSignatureV4Signer, serviceConfiguration: AWSServiceConfiguration) {
        
        apiClient.configuration = serviceConfiguration
        apiClient.configuration.requestInterceptors = [AWSNetworkingRequestInterceptor(), signer] as? [AWSNetworkingRequestInterceptorProtocol]
        apiClient.configuration.baseURL = URL(string: apiURL)
    }
    
    func API(request: CHAPICallObject,
             handler: @escaping (Result<Data?, Error>) -> Void) {
        let awsTask = apiClient.invoke(request.toAWSGatewayRequest())
        awsTask.continueWith( block: { (task: AWSTask) -> Any? in
            
            if let error = task.error {
                handler(.failure(error))
                return nil
            }
            
            guard let response = task.result else {
                handler(.success(nil))
                return nil
            }
            
            switch response.statusCode {
            case 200, 204:
                handler(.success(response.responseData))
            case 404, 401, 403, 409, 502:
                guard let _ = response.responseData else {
                    let error = NSError(domain: "CandyHouseUser", code: response.statusCode, userInfo: ["message": response.rawResponse])
                    handler(.failure(error))
                    return nil
                }
                let error = self.errorFromResponse(response)
                handler(.failure(error))
            default:
                guard let _ = response.responseData else {
                    let error = NSError(domain: "CandyHouseUser", code: response.statusCode, userInfo: ["message": response.rawResponse])
                    handler(.failure(error))
                    return nil
                }
                let error = self.errorFromResponse(response)
                handler(.failure(error))
            }
            return nil
        })
    }
    
    private func errorFromResponse(_ response: AWSAPIGatewayResponse) -> Error {
        do {
            let errorFromServer = try JSONDecoder().decode(CHServerError.self, from: response.responseData!)
            return NSError(domain: "CandyHouseUser", code: response.statusCode, userInfo: ["message": errorFromServer.message])
        } catch {
            return NSError(domain: "CandyHouseUser", code: response.statusCode, userInfo: ["message": response.rawResponse])
        }
    }
}
