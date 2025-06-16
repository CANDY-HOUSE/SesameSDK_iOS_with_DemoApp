//
//  CHHub3.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/26.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation

/// 新增红外设备
public typealias IRDeviceCode = Int
public struct IRDevicePayload: Codable {
    public let uuid: String
    public let model: String
    public var alias: String
    public let deviceUUID: String
    public let state: String
    public let type: IRDeviceCode
    public var keys: [CHHub3IRCode]
    public var code: Int
    
    public init(uuid: String, model: String, alias: String, deviceUUID: String, state: String, type: IRDeviceCode, keys: [CHHub3IRCode], code:Int) {
        self.uuid = uuid
        self.model = model
        self.alias = alias
        self.deviceUUID = deviceUUID
        self.state = state
        self.type = type
        self.keys = keys
        self.code = code
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, model, alias, deviceUUID, keys, type, state, code
    }
}

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


public protocol IRRemoteHandler {
    
    /// 红外设备
    var irRemotes: [IRRemote] { get set }
    
    /// 获取红外设备
    /// - Parameter result: 结果
    func fetchIRDevices(_ result: @escaping CHResult<[IRRemote]>)
    
    /// 创建红外设备
    /// - Parameters:
    ///   - payload: 红外对象
    ///   - result: 结果
    func postIRDevice(_ payload: IRDevicePayload, _ result: @escaping CHResult<CHEmpty>)
    
    /// 更新红外设备
    /// - Parameters:
    ///   - payload: 要更新的字段
    ///   - result: 结果
    func updateIRDevice(_ payload: [String: String], _ result: @escaping CHResult<CHEmpty>)
    
    /// uuid 获取红外按键
    /// - Parameters:
    ///   - uuid: 遥控器id
    ///   - result: 结果
    func getIRDeviceKeysByUid(_ uuid: String, _ result: @escaping CHResult<[CHHub3IRCode]>)
    
    /// 删除红外设备
    /// - Parameters:
    ///   - uuid: 遥控器id
    ///   - result: 结果
    func deleteIRDevice(_ uuid: String, _ result: @escaping CHResult<CHEmpty>)
    
    /// IR 码刪除
    /// - Parameters:
    ///   - id: ir id
    ///   - result: 結果
    func irCodeDelete(uuid: String, keyUUID: String, result: @escaping CHResult<CHEmpty>)
    
    /// IR 碼的編輯
    /// - Parameters:
    ///   - id: ir id
    ///   - name: ir name
    ///   - result: 結果
    func irCodeChange(uid: String, keyUUID: String, name: String, result: @escaping CHResult<CHEmpty>)
    
    
    ///  订阅红外学习数据主题
    /// - Parameters:
    ///   - result: 結果
    func subscribeLearnData(result: @escaping CHResult<Data>)
    
    ///  取消红外学习数据主题订阅
    /// - Parameters:
    func unsubscribeLearnData()
    
    ///  上传红外自学习数据
    /// - Parameters:
    ///   - data: 红外码流
    ///   - hub3DeviceUUID:  hub3 device uuid
    ///   - irDataNameUUID:  自学习码流对应 uuid
    ///   - irDeviceUUID:  自学习设备对应 uuid
    ///   - keyUUID:  自学习按键 uuid
    ///   - result:  結果
    func addLearnData(data:Data, hub3DeviceUUID: String, irDataNameUUID:String, irDeviceUUID:String, keyUUID: String, result: @escaping CHResult<CHEmpty>)
}

public protocol CHHub3: CHWifiModule2, IRRemoteHandler {
    
    var status: Hub3Status { get }
    var hub3Brightness: UInt8 { get }
    /// 添加SSM 設備
    /// - Parameters:
    ///   - device: device 對象
    ///   - nickName: deviceName，同步给 matter
    ///   - matterProductModel: matter 模式
    ///   - result: 結果
    func insertSesame(_ device: CHDevice, nickName: String, matterProductModel: MatterProductModel, result: @escaping CHResult<CHEmpty>)
    
    /// IR 模式獲取
    /// - Parameter result: 0 正常模式，1 讀取模式
    func irModeGet(result: @escaping CHResult<UInt8>)
    
    /// 設置IR 模式
    /// - Parameters:
    ///   - mode: 0 正常模式，1 讀取模式
    ///   - result: 結果
    func irModeSet(mode: UInt8, result: @escaping CHResult<CHEmpty>)
    
    /// IR 發射
    /// - Parameters:
    ///   - id: ir id
    ///   - irDeviceUUID: ir 设备 uuid
    ///   - result: 結果
    func irCodeEmit(id: String, irDeviceUUID: String, result: @escaping CHResult<CHEmpty>)
    
    /// IR 碼的獲取，以 publish 形式返回
    /// - Parameter result: 發送結果
    func irCodesGet(result: @escaping CHResult<CHEmpty>)
    
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
}

public protocol CHHub3Delegate: CHWifiModule2Delegate {
    
    /// IR 指令改變
    /// - Parameters:
    ///   - device: 設備對象
    ///   - id: ir id
    ///   - name: ir name
    func onIRCodeChanged(device: CHHub3, ir: CHHub3IRCode)
    
    /// IR 接受
    /// - Parameters:
    ///   - device: 設備對象
    ///   - id: ir id
    ///   - name: ir name
    func onIRCodeReceive(device: CHHub3, ir: CHHub3IRCode)
    
    /// IR 開始接受
    /// - Parameter device: 設備對象
    func onIRCodeReceiveStart(device: CHHub3)
    
    /// IR 完成接受
    /// - Parameter device: 設備對象
    func onIRCodeReceiveEnd(device: CHHub3)
    
    /// 接收到 mode 改變
    /// - Parameters:
    ///   - device: 設備對象
    ///   - mode: 模式 ，0 正常模式 1 錄入模式
    func onIRModeReceive(device: CHHub3, mode: UInt8)

    /// 接收到Hub 3 LED亮度
    /// - Parameters:
    ///   - device: 設備對象
    ///   - brightness:亮度值
    func onHub3BrightnessReceive(device: CHHub3, brightness: UInt8)
}

public extension CHHub3Delegate {
    
    /// IR 指令改變
    /// - Parameters:
    ///   - device: 設備對象
    ///   - id: ir id
    ///   - name: ir name
    func onIRCodeChanged(device: CHHub3, ir: CHHub3IRCode){}
    
    /// IR 接受
    /// - Parameters:
    ///   - device: 設備對象
    ///   - id: ir id
    ///   - name: ir name
    func onIRCodeReceive(device: CHHub3, ir: CHHub3IRCode){}
    
    /// IR 開始接受
    /// - Parameter device: 設備對象
    func onIRCodeReceiveStart(device: CHHub3){}
    
    /// IR 完成接受
    /// - Parameter device: 設備對象
    func onIRCodeReceiveEnd(device: CHHub3){}
    
    /// 接收到 mode 改變
    /// - Parameters:
    ///   - device: 設備對象
    ///   - mode: 模式 ，0 正常模式 1 錄入模式
    func onIRModeReceive(device: CHHub3, mode: UInt8){}
    
    /// 接收到Hub 3 LED亮度
    /// - Parameters:
    ///   - device: 設備對象
    ///   - brightness:亮度值
    func onHub3BrightnessReceive(device: CHHub3, brightness: UInt8){}
}

public struct CHHub3IRCode: Codable, Equatable {
    public var keyUUID: String
    public var name: String?
    
    public init(keyUUID: String, name: String?) {
        self.keyUUID = keyUUID
        self.name = name
    }
    
    enum CodingKeys: CodingKey {
        case keyUUID
        case name
    }
    
    static func fromData(_ buf: Data) -> CHHub3IRCode {
        let codeId = String(format: "%02X", buf[0])
        return CHHub3IRCode(keyUUID: codeId, name: nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyUUID, forKey: .keyUUID)
        if (name != nil) {
            try container.encode(name, forKey: .name)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyUUID = try container.decode(String.self, forKey: .keyUUID)
        name = try container.decode(String.self, forKey: .name)
    }
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

