//
//  AccountManager.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Amplify
import Foundation

#if DEBUG
let awsApiGatewayBaseUrl = "https://app.candyhouse.co/dev"
#else
let awsApiGatewayBaseUrl = "https://app.candyhouse.co/prod"
#endif

enum CHAppIdentify {
    private static let keyTag = "co.candyhouse.sesame2.AppIdentifyID"
    static let current: String = {
        let id: String
        if let existing = CHKeychain.string(forKey: keyTag), !existing.isEmpty {
            id = existing
        } else {
            id = generate()
            CHKeychain.setString(id, forKey: keyTag)
        }
        L.d("[AppIdentifyID] =>", id)
        return id
    }()

    private static func generate() -> String {
        let region = CHConfiguration.shared.clientId.split(separator: ":").first.map(String.init) ?? "ap-northeast-1"
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "\(region):\(hex)"
    }
}

public class CHAPIClient {
    public static let shared = CHAPIClient()
    let apiKey: String
    
    @discardableResult
    public static func initialize() -> CHAPIClient {
        shared
    }
    
    public init(apiKey: String = CHConfiguration.shared.apiKey) {
        self.apiKey = apiKey
    }
}
