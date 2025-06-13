//
//  CHDataToHistoryTag+.swift
//  SesameUI
//
//  Created by eddy on 2025/5/13.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

enum UUID4HistoryTagType: UInt16, CaseIterable {
    case nameUuidTypeIosUserBleUuid = 0x000f               // iOS ble 开/关 锁
    case nameUuidTypeIosUserWifiUuid = 0x0011              // iOS IOT 开/关 锁
}
