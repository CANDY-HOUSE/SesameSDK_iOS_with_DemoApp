//
//  CHAPICallObject.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2020/11/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Amplify

struct CHAPICallObject {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put =  "PUT"
        case delete = "DELETE"
    }

    var method: Method
    var body: Any?
    var query: [AnyHashable: Any]?
    var urlString: String


    init(_ method: Method, _ urlString: String, _ body: Any? = nil) {
        self.method = method
        self.urlString = urlString
        self.body = body
    }

    init(_ method: Method, _ urlString: String, queryParameters: [AnyHashable: Any]) {
        self.method = method
        self.urlString = urlString
        self.query = queryParameters
    }

    func toRESTRequest(apiKey: String) throws -> RESTRequest {
        let bodyData: Data?
        if let data = body as? Data {
            bodyData = data
        } else if let body {
            bodyData = try JSONSerialization.data(withJSONObject: body)
        } else {
            bodyData = nil
        }
        let queryParameters = query?.reduce(into: [String: String]()) { result, item in
            result[String(describing: item.key)] = String(describing: item.value)
        }
        return RESTRequest(
            apiName: CHAWSManager.apiName,
            path: urlString,
            headers: [
                "Content-Type": "application/json",
                "x-api-key": apiKey,
                "AppIdentifyID": CHAppIdentify.current
            ],
            queryParameters: queryParameters,
            body: bodyData
        )
    }
}

