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
    public let clientId = AWSConfig.clientId
    public let appGroup = "group.candyhouse.widget"
    
    public var regionName: String {
        clientId.split(separator: ":").first.map(String.init) ?? "ap-northeast-1"
    }
}
