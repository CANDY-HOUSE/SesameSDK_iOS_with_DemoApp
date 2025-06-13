//
//  CHDeviceInfo.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/05/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation

/// 上傳設備GPS Model
struct CHDeviceInfo: Codable {
    let deviceUUID: String
    let deviceModel: String
    let longitude: String
    let latitude: String
}
