//
//  CHAPICallObject.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2020/11/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import AWSCore
import AWSAPIGateway
import AWSIoT
#endif

struct CHAPICallObject {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put =  "PUT"
        case delete = "DELETE"
    }

    var request: String
    var body: Any?
    var query: [AnyHashable: Any]?
    var urlString: String


    init(_ method: Method, _ urlString: String, _ body: Any? = nil) {
        self.request = method.rawValue
        self.urlString = urlString
        self.body = body
    }

    init(_ method: Method, _ urlString: String, queryParameters: [AnyHashable: Any]) {
        self.request = method.rawValue
        self.urlString = urlString
        self.query = queryParameters
    }

    func toAWSGatewayRequest() -> AWSAPIGatewayRequest {
        let requestQWS =  AWSAPIGatewayRequest(httpMethod: request, urlString: urlString, queryParameters: self.query, headerParameters: ["Content-Type": "application/json"], httpBody: body)
        return requestQWS
    }
}


