//
//  Request.swift
//  Sesame2SDK
//
//  Created by tse on 2020/3/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

#if os(iOS)
import AWSCore
import AWSAPIGateway
#elseif os(watchOS)
import WatchKit
#endif
import Foundation

extension CHAccountManager {
    func API(request: CHAPICallObject,
                         handler: @escaping (Result<Data?, Error>) -> Void) {

        let awsTask = apiGatewayClient.invoke(request.toAWSGatewayRequest())
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
                    let error = NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
                    handler(.failure(error))
                    return nil
                }
                let error = self.errorFromResponse(response)
                handler(.failure(error))
            default:
                guard let _ = response.responseData else {
                    let error = NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
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
            return NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": errorFromServer.message])
        } catch {
            return NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
        }
    }
}

public class CHServerError: Codable {
    public var message: String = ""
    enum CodingKeys : String, CodingKey {
        case message
    }
}
