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
    // 关联的 ssm keys
    let ssks: String?
    // 当前固件版本号
    public var v: String?
    // s3 获取的最新版本号
    public var hub3LastFirmwareVer: String
    // eventType change 的时间
    let timestamp: Int?
    // 固件携带上来的时间戳
    let ts: Int?
    // 固件上报Wi-Fi 名称
    let wifi_ssid: String?
    // 固件上报Wi-Fi 密码
    let wifi_password: String?
    
    init(eventType: String?, ssks: String?, v: String? = nil, hub3LastFirmwareVer: String, timestamp: Int?, ts: Int?, wifi_ssid: String?, wifi_password: String?) {
        self.eventType = eventType
        self.ssks = ssks
        self.v = v
        self.hub3LastFirmwareVer = hub3LastFirmwareVer
        self.timestamp = timestamp
        self.ts = ts
        self.wifi_ssid = wifi_ssid
        self.wifi_password = wifi_password
    }
}

