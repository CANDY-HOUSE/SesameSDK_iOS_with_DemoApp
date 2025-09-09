//
//  IrControlItem.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

struct IrControlItem {
    let id: Int
    let type: ItemType
    let title: String
    let value: String
    let isSelected: Bool
    let iconRes: String
    let optionCode: String
    
    // 提供默认值的初始化器
    init(
        id: Int,
        type: ItemType,
        title: String,
        value: String = "",
        isSelected: Bool = false,
        iconRes: String,
        optionCode: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.value = value
        self.isSelected = isSelected
        self.iconRes = iconRes
        self.optionCode = optionCode
    }
}
// 主配置结构体
struct UIControlConfig: Codable {
    let controls: [ControlConfig]
    let settings: UIParamsSettings
}

struct ControlConfig: Codable, CustomStringConvertible {
    let id: Int
    let type: String
    let titleIndex: Int
    let titles: [String]
    let icons: [String]
    let defaultValue: String
    let operateCode: String
    
    init(
        id: Int,
        type: String,
        titleIndex: Int,
        titles: [String] = [],
        icons: [String] = [],
        defaultValue: String = "",
        operateCode: String
    ) {
        self.id = id
        self.type = type
        self.titleIndex = titleIndex
        self.titles = titles
        self.icons = icons
        self.defaultValue = defaultValue
        self.operateCode = operateCode
    }
    
    // CustomStringConvertible 协议实现
    var description: String {
        return "ControlConfig(id=\(id), type='\(type)', titleIndex=\(titleIndex), titles=\(titles), icons=\(icons), defaultValue='\(defaultValue)', optionCode='\(operateCode)')"
    }
}

struct UIParamsSettings: Codable {
    let temperature: TemperatureSettings?
    let layout: LayoutSettings
}

struct TemperatureSettings: Codable {
    let min: Int
    let max: Int
    let `default`: Int
    let step: Int
}

struct LayoutSettings: Codable {
    let columns: Int
    let spacing: Int
}

struct States: Codable {
    let options: [String]
    let `default`: String
}

struct AnimationSettings: Codable {
    let duration: Int64
    let type: String
}

// 枚举类型
enum ItemType: String, Codable {
    // 空调
    case powerStatusOn = "POWER_STATUS_ON"
    case powerStatusOff = "POWER_STATUS_OFF"
    case temperatureValue = "TEMPERATURE_VALUE"
    case tempControlAdd = "TEMP_CONTROL_ADD"
    case tempControlReduce = "TEMP_CONTROL_REDUCE"
    case mode = "MODE"
    case fanSpeed = "FAN_SPEED"
    case windDirection = "SWING_VERTICAL"
    case autoWindDirection = "SWING_HORIZONTAL"
    
    // 电视
    case mute = "MUTE"
    case back = "BACK"
    case up = "UP"
    case menu = "MENU"
    case left = "LEFT"
    case ok = "OK"
    case right = "RIGHT"
    case volumeUp = "VOLUME_UP"
    case down = "DOWN"
    case channelUp = "CHANNEL_UP"
    case volumeDown = "VOLUME_DOWN"
    case home = "HOME"
    case channelDown = "CHANNEL_DOWN"
    
    // 灯
    case brightnessUp = "BRIGHTNESS_UP"
    case brightnessDown = "BRIGHTNESS_DOWN"
    case colorTempUp = "COLOR_TEMP_UP"
    case colorTempDown = "COLOR_TEMP_DOWN"
    
    case power = "POWER"
}
