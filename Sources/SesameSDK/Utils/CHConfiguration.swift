//
//  CHConfiguration.swift
//  Sesame2SDK
//  [AWS config檔]
//  Created by YuHan Hsiao on 2020/6/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public final class CHConfiguration {
    public static let shared = CHConfiguration()
    public let apiKey = AWSConfig.apiKey
    public let clientId = CHConfiguration.loadIdentityPoolId()
    public let appGroup = "group.candyhouse.widget"

    public var regionName: String {
        clientId.split(separator: ":").first.map(String.init) ?? "ap-northeast-1"
    }
    
    private static func loadIdentityPoolId() -> String {
        guard let url = Bundle.main.url(forResource: "awsconfiguration", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let credentialsProvider = json["CredentialsProvider"] as? [String: Any],
              let cognitoIdentity = credentialsProvider["CognitoIdentity"] as? [String: Any],
              let defaultConfig = cognitoIdentity["Default"] as? [String: Any],
              let poolId = defaultConfig["PoolId"] as? String else {
            return ""
        }
        return poolId
    }
}
