//
//  CHDeviceProtocol.swift
//  SesameSDK
//
//  Created by tse on 2023/5/11.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
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

}

extension SesameItemCode {

    var plainName: String {
        switch self {
        case .none:
            return "none"
        case .registration:
            return "registration"
        case .login:
            return "login"
        case .user:
            return "user"
        case .history:
            return "history"
        case .versionTag:
            return "versionTag"
        case .disconnectRebootNow:
            return "disconnectRebootNow"
        case .enableDFU:
            return "enableDFU"
        case .time:
            return "time"
        case .bleConnectionParam:
            return "bleConnectionParam"
        case .bleAdvParam:
            return "bleAdvParam"
        case .autolock:
            return "autolock"
        case .serverAdvKick:
            return "serverAdvKick"
        case .mechSetting:
            return "mechSetting"
        case .mechStatus:
            return "mechStatus"
        case .lock:
            return "lock"
        case .unlock:
            return "unlock"
        case .moveTo:
            return "moveTo"
        case .driveDirection:
            return "driveDirection"
        case .stop:
            return "stop"
        case .detectDir:
            return "detectDir"

        case .sesame2Token:
            return "sesame2Token"
        case .initalization:
            return "initalization"
        case .IRER:
            return "IRER"
        case .timeNoSig:
            return "timeNoSig"
        case .magnet:
            return "magnet"
        case .toggle:
            return "SSM2_ITEM_CODE_Toggle"
        case .click:
            return "CLICK"
        case .addSesame:
            return "addSesame"
        case .pubKeySesame:
            return "pubKeySesame"
        case .removeSesame:
            return "removeSesame"
        case .reset:
            return "reset"
        case .notifyLockDown:
            return "notifyLockDown"
        case .SSM_OS3_CARD_CHANGE:
            return "SSM_OS3_CARD_CHANGE"
        case .SSM_OS3_CARD_DELETE:
            return "SSM_OS3_CARD_DELETENGE"
        case .SSM_OS3_CARD_GET:
            return "SSM_OS3_CARD_GETCHANGE"
        case .SSM_OS3_CARD_NOTIFY:
            return "SSM_OS3_CARD_NOTIFYNGE"
        case .SSM_OS3_CARD_LAST:
            return "SSM_OS3_CARD_LASTHANGE"
        case .SSM_OS3_CARD_FIRST:
            return "SSM_OS3_CARD_FIRSTANGE"
        case .SSM_OS3_CARD_MODE_GET:
            return "SSM_OS3_CARD_MODE_GETE"
        case .SSM_OS3_CARD_MODE_SET:
            return "SSM_OS3_CARD_MODE_SETE"
        case .SSM_OS3_FINGERPRINT_CHANGE:
            return "SSM_OS3_FINGERPRINT_CHANGE"
        case .SSM_OS3_FINGERPRINT_DELETE:
            return "SSM_OS3_FINGERPRINT_DELETE"
        case .SSM_OS3_FINGERPRINT_GET:
            return "SSM_OS3_FINGERPRINT_GET"
        case .SSM_OS3_FINGERPRINT_NOTIFY:
            return "SSM_OS3_FINGERPRINT_NOTIFY"
        case .SSM_OS3_FINGERPRINT_LAST:
            return "SSM_OS3_FINGERPRINT_LAST"
        case .SSM_OS3_FINGERPRINT_FIRST:
            return "SSM_OS3_FINGERPRINT_FIRST"
        case .SSM_OS3_FINGERPRINT_MODE_GET:
            return "SSM_OS3_FINGERPRINT_MODE_GET"
        case .SSM_OS3_FINGERPRINT_MODE_SET:
            return "SSM_OS3_FINGERPRINT_MODE_SET"
        case .SSM_OS3_PASSCODE_CHANGE:
            return "SSM_OS3_PASSCODE_CHANGE"
        case .SSM_OS3_PASSCODE_DELETE:
            return "SSM_OS3_PASSCODE_DELETE"
        case .SSM_OS3_PASSCODE_GET:
            return "SSM_OS3_PASSCODE_GETGE"
        case .SSM_OS3_PASSCODE_NOTIFY:
            return "SSM_OS3_PASSCODE_NOTIFY"
        case .SSM_OS3_PASSCODE_LAST:
            return "SSM_OS3_PASSCODE_LASTE"
        case .SSM_OS3_PASSCODE_FIRST:
            return "SSM_OS3_PASSCODE_FIRST"
        case .SSM_OS3_PASSCODE_MODE_GET:
            return "SSM_OS3_PASSCODE_MODE_GET"
        case .SSM_OS3_PASSCODE_MODE_SET:
            return "SSM_OS3_PASSCODE_MODE_SET"
        case .DOOR_OPEN:
            return "DOOR_OPEN"
        case .DOOR_CLOSE:
            return "DOOR_CLOSE"
        case .OPS_CONTROL:
            return "OPS_CONTROL"
        }

    }
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
    func getBatteryVoltage() -> Float
    func getBatteryPrecentage() -> Int
    
}

public extension CHSesameProtocolMechStatus{
    var isClutchFailed: Bool { return false }
    var isBatteryCritical: Bool { return false }
    var isInUnlockRange: Bool { return false }
    var isInLockRange: Bool { return false }
    var isStop: Bool?  { return true }
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
    var productModel: CHProductModel! { get set }
//    func goIOT()
    func login(token: String?)
}
