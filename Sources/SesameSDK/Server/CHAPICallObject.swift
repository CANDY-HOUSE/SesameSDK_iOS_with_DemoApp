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


public struct PublicAPICallObject {
    public enum HTTPMethod: String, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    public let method: HTTPMethod
    public let path: String
    public let queryParameters: [AnyHashable: Any]?
    public let body: Any?
    
    // 公开的初始化方法
    public init(method: HTTPMethod,
                path: String,
                queryParameters: [AnyHashable: Any]? = nil,
                body: Any? = nil) {
        self.method = method
        self.path = path
        self.queryParameters = queryParameters
        self.body = body
    }
    
    // 便利初始化方法
    public init(_ method: HTTPMethod, _ path: String, queryParameters: [AnyHashable: Any]) {
        self.init(method: method, path: path, queryParameters: queryParameters, body: nil)
    }
    
    public init(_ method: HTTPMethod, _ path: String, _ body: Any? = nil) {
        self.init(method: method, path: path, queryParameters: nil, body: body)
    }
    
    // 转换为内部的 CHAPICallObject
    internal func toCHAPICallObject() -> CHAPICallObject {
        // 将公开的 HTTPMethod 转换为内部的 Method
        guard let internalMethod = CHAPICallObject.Method(rawValue: method.rawValue) else {
            fatalError("Invalid HTTP method: \(method.rawValue)")
        }
        
        if let queryParams = queryParameters {
            return CHAPICallObject(internalMethod, path, queryParameters: queryParams)
        } else {
            return CHAPICallObject(internalMethod, path, body)
        }
    }
}


