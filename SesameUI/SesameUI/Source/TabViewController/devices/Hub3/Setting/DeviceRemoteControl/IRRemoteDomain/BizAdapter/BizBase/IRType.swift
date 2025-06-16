//
//  IRType.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

struct IRType {
    // 使用静态常量
    static let DEVICE_REMOTE_TV: Int = 0x2000
    static let DEVICE_REMOTE_STB: Int = 0x4000
    static let DEVICE_REMOTE_DVD: Int = 0x6000
    static let DEVICE_REMOTE_FANS: Int = 0x8000
    static let DEVICE_REMOTE_PJT: Int = 0xA000
    static let DEVICE_REMOTE_AIR: Int = 0xC000
    static let DEVICE_REMOTE_LIGHT: Int = 0xE000
    static let DEVICE_REMOTE_IPTV: Int = 0x2100
    static let DEVICE_REMOTE_DC: Int = 0x2300
    static let DEVICE_REMOTE_BOX: Int = 0x2500
    static let DEVICE_REMOTE_AP: Int = 0x2700
    static let DEVICE_REMOTE_AUDIO: Int = 0x2900
    static let DEVICE_REMOTE_POWER: Int = 0x2B00
    static let DEVICE_REMOTE_SLR: Int = 0x2D00
    static let DEVICE_REMOTE_HW: Int = 0x2F00
    static let DEVICE_REMOTE_ROBOT: Int = 0x3100
    static let DEVICE_REMOTE_CUSTOM: Int = 0xFE00
    static let DEVICE_ADD: Int = -0x1000000
    
    // 使用计算属性处理位运算
    static let DEVICE_REMOTE_TV_EX: Int = 0x2000 | 0x10000
    static let DEVICE_REMOTE_STB_EX: Int = 0x4000 | 0x10000
    static let DEVICE_REMOTE_DVD_EX: Int = 0x6000 | 0x10000
    static let DEVICE_REMOTE_FANS_EX: Int = 0x8000 | 0x10000
    static let DEVICE_REMOTE_PJT_EX: Int = 0xA000 | 0x10000
    static let DEVICE_REMOTE_AIR_EX: Int = 0xC000 | 0x10000
    static let DEVICE_REMOTE_LIGHT_EX: Int = 0xE000 | 0x10000
    static let DEVICE_REMOTE_IPTV_EX: Int = 0x2100 | 0x10000
    static let DEVICE_REMOTE_DC_EX: Int = 0x2300 | 0x10000
    static let DEVICE_REMOTE_BOX_EX: Int = 0x2500 | 0x10000
    static let DEVICE_REMOTE_AP_EX: Int = 0x2700 | 0x10000
    static let DEVICE_REMOTE_AUDIO_EX: Int = 0x2900 | 0x10000
    static let DEVICE_REMOTE_POWER_EX: Int = 0x2B00 | 0x10000
    static let DEVICE_REMOTE_SLR_EX: Int = 0x2D00 | 0x10000
    static let DEVICE_REMOTE_HW_EX: Int = 0x2F00 | 0x10000
    static let DEVICE_REMOTE_CUSTOM_EX: Int = -0x2000000 | 0x10000
    
    // 私有初始化器防止实例化
    private init() {}
}
