//
//  Request.swift
//  Sesame2SDK
//
//  Created by tse on 2020/3/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Amplify
import AWSAPIPlugin
import Foundation

extension CHAPIClient {
    func API(request: CHAPICallObject,
                         handler: @escaping (Result<Data?, Error>) -> Void) {

        Task {
            do {
                try CHAWSManager.configure()
                let restRequest = try request.toRESTRequest(apiKey: apiKey)
                let data: Data
                switch request.method {
                case .get:
                    data = try await Amplify.API.get(request: restRequest)
                case .post:
                    data = try await Amplify.API.post(request: restRequest)
                case .put:
                    data = try await Amplify.API.put(request: restRequest)
                case .delete:
                    data = try await Amplify.API.delete(request: restRequest)
                }
                handler(.success(data.isEmpty ? nil : data))
            } catch {
                handler(.failure(errorFromAmplify(error)))
            }
        }

    }

    private func errorFromAmplify(_ error: Error) -> Error {
        guard let apiError = error as? APIError,
              case let .httpStatusError(statusCode, response) = apiError else { return error }
        let data = (response as? AWSHTTPURLResponse)?.body
        let message = data.flatMap { try? JSONDecoder().decode(CHServerError.self, from: $0).message }
            ?? data.flatMap { String(data: $0, encoding: .utf8) }
            ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)
        return NSError(domain: "Sesame2SDK", code: statusCode, userInfo: ["message": message])
    }
}

public class CHServerError: Codable {
    public var message: String = ""
    enum CodingKeys : String, CodingKey {
        case message
    }
}
