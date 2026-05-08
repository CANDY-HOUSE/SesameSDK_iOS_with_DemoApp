//
//  CHHub3.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/26.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation

public protocol CHHub3: CHWifiModule2 {
    var status: Hub3Status { get }
}

/// 从 AWS 数据库获取的 Hub3 状态
public struct Hub3Status : Codable {
    // conected disconneced null
    let eventType: String?
}

