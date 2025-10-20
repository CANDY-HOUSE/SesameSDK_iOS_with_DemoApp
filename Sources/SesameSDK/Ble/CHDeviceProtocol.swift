//
//  CHDeviceProtocol.swift
//  SesameSDK
//
//  Created by tse on 2023/5/11.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import Foundation
enum SesameItemCode: UInt8 {
    case none = 0
    case registration = 1          // C
    case login = 2                 // R
    case user = 3                  // CRUD
    case history = 4               // RD
    case versionTag = 5            // R
    case disconnectRebootNow = 6   // S
    case enableDFU = 7             // RU
    case time = 8                  // RU
    case bleConnectionParam = 9    // RU
    case bleAdvParam = 10          // RU
    case autolock = 11             // RU
    case serverAdvKick = 12        // S
    case sesame2Token = 13        // S
    case initalization = 14        // S
    case IRER = 15
    case timeNoSig = 16
    case magnet = 17
    case historyDelete = 18
    /*
     * Mechanic-dependent commands
     */
    case mechSetting = 80          // RU
    case mechStatus = 81           // RP
    case lock = 82                 // A
    case unlock = 83               // A
    case moveTo = 84               // A
    case driveDirection = 85       // A
    case stop = 86                 // S
    case detectDir = 87            // A
    case toggle = 88
    case click = 89
    
    case DOOR_OPEN = 90
    case DOOR_CLOSE = 91
    case OPS_CONTROL = 92

    /*
     * Bot2
     */
    case scriptSetting = 93
    case scriptSelect = 94
    case scriptCurrent = 95
    case scriptNameList = 96
    case BOT2_ITEM_CODE_RUN_SCRIPT_0 = 170
    case BOT2_ITEM_CODE_RUN_SCRIPT_1 = 171
    case BOT2_ITEM_CODE_RUN_SCRIPT_2 = 172
    case BOT2_ITEM_CODE_RUN_SCRIPT_3 = 173
    case BOT2_ITEM_CODE_RUN_SCRIPT_4 = 174
    case BOT2_ITEM_CODE_RUN_SCRIPT_5 = 175
    case BOT2_ITEM_CODE_RUN_SCRIPT_6 = 176
    case BOT2_ITEM_CODE_RUN_SCRIPT_7 = 177
    case BOT2_ITEM_CODE_RUN_SCRIPT_8 = 178
    case BOT2_ITEM_CODE_RUN_SCRIPT_9 = 179
    case BOT2_ITEM_CODE_EDIT_SCRIPT = 181

    case addSesame = 101
    case pubKeySesame = 102
    case removeSesame = 103
    case reset = 104
    case notifyLockDown = 106

    case SSM_OS3_CARD_CHANGE = 107
    case SSM_OS3_CARD_DELETE = 108
    case SSM_OS3_CARD_GET = 109
    case SSM_OS3_CARD_NOTIFY = 110
    case SSM_OS3_CARD_LAST = 111
    case SSM_OS3_CARD_FIRST = 112
    case SSM_OS3_CARD_MODE_GET = 113
    case SSM_OS3_CARD_MODE_SET = 114

    case SSM_OS3_FINGERPRINT_CHANGE = 115
    case SSM_OS3_FINGERPRINT_DELETE = 116
    case SSM_OS3_FINGERPRINT_GET = 117
    case SSM_OS3_FINGERPRINT_NOTIFY = 118
    case SSM_OS3_FINGERPRINT_LAST = 119
    case SSM_OS3_FINGERPRINT_FIRST = 120
    case SSM_OS3_FINGERPRINT_MODE_GET = 121
    case SSM_OS3_FINGERPRINT_MODE_SET = 122

    case SSM_OS3_PASSCODE_CHANGE = 123
    case SSM_OS3_PASSCODE_DELETE = 124
    case SSM_OS3_PASSCODE_GET = 125
    case SSM_OS3_PASSCODE_NOTIFY = 126
    case SSM_OS3_PASSCODE_LAST = 127
    case SSM_OS3_PASSCODE_FIRST = 128
    case SSM_OS3_PASSCODE_MODE_GET = 129
    case SSM_OS3_PASSCODE_MODE_SET = 130
    case REMOTE_NANO_ITEM_CODE_SET_TRIGGER_DELAYTIME = 190
    case REMOTE_NANO_ITEM_CODE_PUB_TRIGGER_DELAYTIME = 191

    // hub 3
    case HUB3_ITEM_CODE_WIFI_SSID = 131
    case HUB3_ITEM_CODE_SSID_FIRST = 132
    case HUB3_ITEM_CODE_SSID_NOTIFY = 133
    case HUB3_ITEM_CODE_SSID_LAST = 134
    case HUB3_ITEM_CODE_WIFI_PASSWORD = 135
    case HUB3_UPDATE_WIFI_SSID = 136
    case HUB3_MATTER_PAIRING_CODE = 137
    
    // 添加密码
    case SSM_OS3_PASSCODE_ADD = 138
    
    // 添加卡片
    case SSM_OS3_CARD_ADD = 140
    
    case SSM_OS3_IR_MODE_SET = 143
    case SSM_OS3_IR_CODE_CHANGE = 144
    case SSM_OS3_IR_CODE_EMIT = 145
    case SSM_OS3_IR_CODE_GET = 146
    case SSM_OS3_IR_CODE_LAST = 147
    case SSM_OS3_IR_CODE_FIRST = 148
    case SSM_OS3_IR_CODE_DELETE = 149
    case SSM_OS3_IR_MODE_GET = 150
    case SSM_OS3_IR_CODE_NOTIFY = 151
    case HUB3_MATTER_PAIRING_WINDOW = 153
    
    // 人脸
    case SSM_OS3_FACE_CHANGE = 154
    case SSM_OS3_FACE_DELETE = 155
    case SSM_OS3_FACE_GET = 156
    case SSM_OS3_FACE_NOTIFY = 157
    case SSM_OS3_FACE_LAST = 158
    case SSM_OS3_FACE_FIRST = 159
    case SSM_OS3_FACE_MODE_GET = 160
    case SSM_OS3_FACE_MODE_SET = 161
    
    // 手掌
    case SSM_OS3_PALM_CHANGE = 162
    case SSM_OS3_PALM_DELETE = 163
    case SSM_OS3_PALM_GET = 164
    case SSM_OS3_PALM_NOTIFY = 165
    case SSM_OS3_PALM_LAST = 166
    case SSM_OS3_PALM_FIRST = 167
    case SSM_OS3_PALM_MODE_GET = 168
    case SSM_OS3_PALM_MODE_SET = 169
    
    // 批量添加卡片
    case STP_ITEM_CODE_CARDS_ADD = 182
    
    // 批量添加密码
    case STP_ITEM_CODE_PASSCODES_ADD = 184
    
    case SSM_OS3_FACE_MODE_DELETE_NOTIFY = 192
    case SSM_OS3_PALM_MODE_DELETE_NOTIFY = 193
    
    // 雷达灵敏度
    case SSM_OS3_RADAR_PARAM_SET = 200
    case SSM_OS3_RADAR_PARAM_PUBLISH = 201
    
    // 重载/轻载 电压值mv
    case SSM3_ITEM_CODE_BATTERY_VOLTAGE = 202
}

extension SesameItemCode {

    var plainName: String {
       return String(describing: self)
    }
}

enum Hub3ItemCode: UInt8 {
    case HUB3_ITEM_CODE_LED_DUTY = 92
}

enum SesameBleSegmentType: UInt8 {
    case plaintext = 1
    case ciphertext = 2
    case unknown = 99
}

enum SesameBleSegmentHead {
    static let content: UInt8 = 0
    static let start: UInt8 = 1
}

enum SesameResultCode: UInt8,Error {
    case success = 0
    case invalidFormat = 1
    case notSupported = 2
    case resultStorageFail = 3
    case invalidSig = 4
    case notFound = 5
    case unknown = 6
    case busy = 7
    case invalidParam = 8
    case invalidAction = 9
}

extension SesameResultCode {
    var plainName: String {
        switch self {
        case .success:
            return "success"
        case .invalidFormat:
            return "invalidFormat"
        case .notSupported:
            return "notSupported"
        case .resultStorageFail:
            return "resultStorageFail"
        case .invalidSig:
            return "invalidSig"
        case .notFound:
            return "notFound"
        case .unknown:
            return "unknown"
        case .busy:
            return "busy"
        case .invalidParam:
            return "invalidParam"
        case .invalidAction:
            return "invalidAction"
        }
    }
}

class SesameBleReceiver {

    var buffer: Data

    init() {
        buffer = Data()
    }

    func feed(_ input: Data) -> (type: SesameBleSegmentType, buffer: Data)? {
        guard input.isEmpty == false else { return nil }
        let seg = input.prefix(MemoryLayout<UInt8>.size)
        let isStartFlag = seg.uint8 & 1
        let parsingType = seg.uint8 >> 1

        if isStartFlag > 0 {
            buffer = input.suffix(from: 1)
        } else {
            buffer += input.suffix(from: 1)
        }

        if parsingType > 0 {
            let buf = buffer
            buffer = Data()
            let type = SesameBleSegmentType(rawValue: UInt8(parsingType)) ?? .unknown
            return (type, buf)
        } else {
            return nil
        }
    }
}

typealias SesameOS3ResponseCallback = (_ payload: SesameOS3CmdResponsePayload) -> Void 
typealias Sesame2ResponseCallback = (_ payload: Sesame2CmdResponsePayload) -> Void
typealias WifiModule2ResponseCallback = (_ payload: WifiModule2CmdResponsePayload) -> Void

class SesameBleTransmiter {
    private let MTU: Int = 20
    var sesame2BleSegmentType: SesameBleSegmentType
    var buffer: Data?

    init(_ type: SesameBleSegmentType, _ input: Data) {
        self.sesame2BleSegmentType = type
        self.buffer = input
    }

    func getChunk() -> Data? {
        if let buffer = buffer {
            let offset = buffer.indices.lowerBound
            let cnt = buffer.count
            var head: UInt8 = offset == 0 ? SesameBleSegmentHead.start : SesameBleSegmentHead.content

            if cnt + 1 > MTU {
                let ret = Data([head]) + buffer[offset...offset + MTU - 2]
                self.buffer = buffer.suffix(from: offset + MTU - 1)
                return ret
            } else {
                head |= sesame2BleSegmentType.rawValue << 1
                let ret = cnt > 0 ? Data([head]) + buffer[offset...offset + cnt - 1] : Data([head])
                self.buffer = nil
                return ret
            }
        } else {
            return nil
        }
    }
}
public enum CHDeviceLoginStatus:String {
    case logined = "logined"
    case unlogined  = "unlogined"
}

public protocol CHSesameProtocolMechStatus {
    var data: Data { get }
    var position: Int16 { get }
    var target: Int16 { get }
    var isClutchFailed: Bool { get }
    var isInLockRange: Bool{ get }
    var isInUnlockRange : Bool { get }
    var isBatteryCritical: Bool { get }
    var isStop: Bool?  { get }
    var isCritical: Bool?  { get }
    func getBatteryVoltage() -> Float
    func getBatteryPrecentage() -> Int
    
}

public extension CHSesameProtocolMechStatus{
    var isClutchFailed: Bool { return false }
    var isBatteryCritical: Bool { return false }
    var isInUnlockRange: Bool { return false }
    var isInLockRange: Bool { return false }
    var isStop: Bool?  { return true }
    var isCritical: Bool?  { return false }
    var position: Int16 {0}
    var target: Int16 {0}
    var data: Data { return Data() }
    func getBatteryPrecentage() -> Int { // [CHDeviceProtocol]共用電量計算曲線
        let voltage = getBatteryVoltage()
        let blocks: [Float] = [5.85, 5.82, 5.79, 5.76, 5.73, 5.70, 5.65, 5.60, 5.55, 5.50, 5.40, 5.20, 5.10, 5.0, 4.8, 4.6]
        let mapping: [Float] = [100.0, 95.0, 90.0, 85.0, 80.0, 70.0, 60.0, 50.0, 40.0, 32.0, 21.0, 13.0, 10.0, 7.0, 3.0, 0.0]
        if voltage >= blocks[0] {
            return Int(mapping[0])
        }
        if voltage <= blocks[blocks.count-1] {
            return Int(mapping[mapping.count-1])
        }
        for i in 0..<blocks.count-1 {
            let upper: CFloat = blocks[i]
            let lower: CFloat = blocks[i+1]
            if voltage <= upper && voltage > lower {
                let value: CFloat = (voltage-lower)/(upper-lower)
                let max = mapping[i]
                let min = mapping[i+1]
                return Int((max-min)*value+min)
            }
        }
        return 0
    }
}

public enum CHDeviceStatus: Equatable {
    case noBleSignal(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "noBleSignal")
    case receivedBle(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "receivedBle")
    case bleConnecting(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "bleConnecting")
    case reset(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "reset")
    case waitingGatt(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "waitingGatt")
    case bleLogining(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "bleLogingIn")
    case readyToRegister(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "readyToRegister")
    case waitingForAuth(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "waitingForAuth")
    case registering(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "registering")
    case dfumode(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "dfumode")

    case locked(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "locked")
    case unlocked(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "unlocked")
    case moved(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "moved")
    case noSettings(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "noSettings")

    // WM2
    case waitApConnect(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "waitApConnect")
    case busy(loginStatus: CHDeviceLoginStatus = .unlogined, desc: String = "busy")
    case iotConnected(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "iotConnected")
    case iotDisconnected(loginStatus: CHDeviceLoginStatus = .logined, desc: String = "iotDisconnected")

    private var value: (status: CHDeviceLoginStatus, desc: String) {
        switch self {
        case .reset(let status, let desc),
             .noBleSignal(let status, let desc),
             .receivedBle(let status, let desc),
             .bleConnecting(let status, let desc),
             .waitingGatt(let status, let desc),
             .bleLogining(let status, let desc),
             .readyToRegister(let status, let desc),
             .waitingForAuth(let status, let desc),
             .registering(let status, let desc),
             .dfumode(let status, let desc),
             .locked(let status, let desc),
             .unlocked(let status, let desc),
             .moved(let status, let desc),
             .noSettings(let status, let desc),
             .waitApConnect(let status, let desc),
             .busy(let status, let desc),
             .iotConnected(let status, let desc),
             .iotDisconnected(let status, let desc):
            return (status, desc)
        }
    }

    public var description: String {
        value.desc
    }

    public var loginStatus: CHDeviceLoginStatus {
        value.status
    }
}

// MARK: - CHDeviceUtil
protocol CHDeviceUtil {
    var advertisement: BleAdv? { get set }
    var sesame2KeyData: CHDeviceKey? { get set }
    var deviceStatus: CHDeviceStatus { get set }
//    var lastLiveTime: TimeInterval? { get set }
    var productModel: CHProductModel! { get set }
    func goIOT()
    func login(token: String?)
}
