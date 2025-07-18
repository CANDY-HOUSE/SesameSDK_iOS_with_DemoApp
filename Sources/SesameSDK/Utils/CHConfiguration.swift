//
//  CHConfiguration.swift
//  Sesame2SDK
//  [AWS config檔]
//  Created by YuHan Hsiao on 2020/6/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import AWSCore
#endif

public final class CHConfiguration {
    public static let shared = CHConfiguration()
    public let apiKey = AWSConfigManager.config.apiKey
    public let clientId = AWSConfigManager.config.clientId
    public let appGroup = "group.candyhouse.widget"
    
    func region() -> AWSRegionType {
        switch clientId.split(separator: ":").first {
        case "ap-northeast-1":
            return AWSRegionType.APNortheast1
        case "ap-northeast-2":
            return AWSRegionType.APNortheast2
        case "ap-east-1":
            return AWSRegionType.APEast1
        case "ap-south-1":
            return AWSRegionType.APSouth1
        case "ap-southeast-1":
            return AWSRegionType.APSoutheast1
        case "ap-southeast-2":
            return AWSRegionType.APSoutheast2
        case "us-west-1":
            return AWSRegionType.USWest1
        case "us-west-2":
            return AWSRegionType.USWest2
        case "us-east-1":
            return AWSRegionType.USEast1
        case "us-east-2":
            return AWSRegionType.USEast2
        default:
            return AWSRegionType.APNortheast1
        }
    }
}
