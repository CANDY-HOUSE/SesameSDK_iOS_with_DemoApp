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
        guard let apiError = error as? APIError else {
            let ns = error as NSError
            return makeError(code: ns.code, message: error.localizedDescription)
        }
        switch apiError {
        case let .httpStatusError(statusCode, response):
            let data = (response as? AWSHTTPURLResponse)?.body
            let message = serverMessage(from: data)
                ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)
            return makeError(code: statusCode, message: message)

        case let .networkError(description, _, underlyingError):
            let code = (underlyingError as NSError?)?.code ?? -1
            let message = underlyingError?.localizedDescription ?? description
            return makeError(code: code, message: message)

        default:
            let underlying = apiError.underlyingError
            let code = (underlying as NSError?)?.code ?? -1
            let message = underlying?.localizedDescription
                ?? apiError.errorDescription
                ?? "\(apiError)"
            return makeError(code: code, message: message)
        }
    }

    private func serverMessage(from data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        if let message = try? JSONDecoder().decode(CHServerError.self, from: data).message,
           !message.isEmpty {
            return message
        }
        return String(data: data, encoding: .utf8)
    }

    private func makeError(code: Int, message: String) -> NSError {
        NSError(domain: "Sesame2SDK", code: code, userInfo: ["message": message])
    }
}

public class CHServerError: Codable {
    public var message: String = ""
    enum CodingKeys : String, CodingKey {
        case message
    }
}
