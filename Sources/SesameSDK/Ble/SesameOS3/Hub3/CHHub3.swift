//
//  CHHub3.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/26.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation


public class IRRemote: Codable {
    public let uuid: String
    public private(set) var alias: String
    public var model: String
    public var type: Int
    public let timestamp: Int
    public private(set) var state: String?
    public var code: Int = 0
    public var haveSave: Bool = true
    public var direction: String = "" // 新添加的字段，默认值为空字符串
    
    public func updateState(_ newState: String?) {
        self.state = newState
    }
    
    public func updateAlias(_ newAlias: String) {
        self.alias = newAlias
    }
    
    public init(uuid: String, alias: String, model: String, type: Int, timestamp: Int, state: String? = nil, code: Int = 0, direction: String = "") {
        self.uuid = uuid
        self.alias = alias
        self.model = model
        self.type = type
        self.timestamp = timestamp
        self.state = state
        self.code = code
        self.haveSave = true
        self.direction = direction
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case alias
        case model
        case type
        case timestamp
        case state
        case code
        case direction
    }
    
    public func clone() -> IRRemote {
        let cloned = IRRemote(
            uuid: self.uuid,
            alias: self.alias,
            model: self.model,
            type: self.type,
            timestamp: self.timestamp,
            state: self.state,
            direction: self.direction
        )
        cloned.code = self.code
        cloned.haveSave = self.haveSave
        return cloned
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? UUID().uuidString
        alias = try container.decode(String.self, forKey: .alias)
        model = try container.decode(String.self, forKey: .model)
        type = try container.decodeIfPresent(Int.self, forKey: .type) ?? 0
        timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp) ?? Int(Date().timeIntervalSince1970)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        code = try container.decodeIfPresent(Int.self, forKey: .code) ?? 0
        direction = try container.decodeIfPresent(String.self, forKey: .direction) ?? ""
        haveSave = true
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(alias, forKey: .alias)
        try container.encode(model, forKey: .model)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encode(code, forKey: .code)
        try container.encode(direction, forKey: .direction)
    }
}

extension IRRemote {
    public func swapRemote(_ irType: Int) -> IRRemote {
       return IRRemote(
            uuid: UUID().uuidString.uppercased(),
            alias: self.alias,
            model: self.model,
            type: irType,
            timestamp: 0,
            state: self.state,
            code: self.code,
            direction: self.direction
        )
    }
}


public protocol CHHub3: CHWifiModule2 {
    /// Hub3 持有红外设备列表
    var irRemotes: [IRRemote] { get set }
    var status: Hub3Status { get }
    var hub3Brightness: UInt8 { get }
    /// 添加SSM 設備
    /// - Parameters:
    ///   - device: device 對象
    ///   - nickName: deviceName，同步给 matter
    ///   - matterProductModel: matter 模式
    ///   - result: 結果
    func insertSesame(_ device: CHDevice, nickName: String, matterProductModel: MatterProductModel, result: @escaping CHResult<CHEmpty>)
    
    /// 獲取matter配對碼
    /// - Parameter result: 結果
    func getMatterParingCode(result: @escaping CHResult<CHHub3MatterSettings>)
    
    /// 打開matter配對模式
    /// - Parameter result: 結果
    func openMatterPairingWindow(result: @escaping CHResult<CHEmpty>)
    
    /// 设置Hub 3 LED亮度
    /// - Parameters:
    ///   - brightness: 亮度值，范围：0-255
    ///   - result: 結果
    func setHub3Brightness(brightness: UInt8, result: @escaping CHResult<UInt8>)
    
    /// 删除红外设备
    /// - Parameters:
    ///   - uuid: 遥控器id
    ///   - result: 结果
    func deleteIRDevice(_ uuid: String, _ result: @escaping CHResult<CHEmpty>)
    
    /// 获取红外设备
    /// - Parameter result: 结果
    func fetchIRDevices(_ result: @escaping CHResult<[IRRemote]>)
}

public protocol CHHub3Delegate: CHWifiModule2Delegate {
    /// 接收到Hub 3 LED亮度
    /// - Parameters:
    ///   - device: 設備對象
    ///   - brightness:亮度值
    func onHub3BrightnessReceive(device: CHHub3, brightness: UInt8)
}

public extension CHHub3Delegate {
    /// 接收到Hub 3 LED亮度
    /// - Parameters:
    ///   - device: 設備對象
    ///   - brightness:亮度值
    func onHub3BrightnessReceive(device: CHHub3, brightness: UInt8){}
}


public struct CHHub3MatterSettings {
    public let qrCode: [UInt8]
    public let manualCode: [UInt8]
    
    init(qrCode: [UInt8], manualCode: [UInt8]) {
        self.qrCode = qrCode
        self.manualCode = manualCode
    }
}

public extension CHHub3MatterSettings {
    static func fromData(_ buf: Data) -> CHHub3MatterSettings? {
        guard buf.count == 35 else { return  nil }
        let qrCode = buf[safeBound: 0...21]!
        let manualCode = buf[safeBound: 22...34]!
        return CHHub3MatterSettings(qrCode: qrCode.bytes, manualCode: manualCode.bytes)
    }
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

