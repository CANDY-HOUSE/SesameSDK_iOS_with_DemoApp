//
//  Sesame2Payload.swift
//  sesame2-sdk
//  Created by Cerberus on 2019/08/24.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation

func to<T>(_ buf: Data) -> T? {
    return buf.withUnsafeBytes({ $0.bindMemory(to: T.self).first })
}

// MARK: - Request
struct Sesame2Payload {
    var opCode: Sesame2OpCode
    var itemCode: SesameItemCode
    var data: Data

    init(_ opCode: Sesame2OpCode, _ itemCode: SesameItemCode, _ data: Data? = nil) {
        self.opCode = opCode
        self.itemCode = itemCode
        self.data = data ?? Data()
    }

    init(_ payload: Data) {
        var content = payload.copyData
        let opCodeData = content[0...0].toUInt8()
        let itCodeData = content[1...1].toUInt8()

        opCode = Sesame2OpCode(rawValue: opCodeData) ?? Sesame2OpCode.undefine
        itemCode = SesameItemCode(rawValue: itCodeData ) ?? SesameItemCode.none
        data = content[2...].copyData
    }

    func toDataWithHeader() -> Data {
        let itemCodeData = itemCode.rawValue.data
        let opCodeData =   opCode.rawValue.data
        let header = opCodeData + itemCodeData

        return  header + data
    }

    func toDataWithHeader(withCipher cipher: Sesame2BleCipher) throws  -> Data {
        return try cipher.encrypt(toDataWithHeader())
    }

}

// MARK: - Parse
struct Sesame2NotifyPayload {
    let opCode: Sesame2OpCode?
    let payload: Data
    
    init(data: Data) {
        var content = data.copyData
        self.opCode = Sesame2OpCode(rawValue: content[0...0].toUInt8())
        self.payload = content[1...].copyData
    }
}

struct Sesame2CmdResponsePayload {
    let cmdItCode: SesameItemCode
    let cmdOpCode: Sesame2OpCode
    let cmdResultCode: SesameResultCode
    let data: Data
    
    init(_ data: Data) {
        var content = data.copyData
        self.cmdItCode = SesameItemCode(rawValue: content[0...0].toUInt8())!
        self.cmdOpCode = Sesame2OpCode(rawValue: content[1...1].toUInt8())!
        self.cmdResultCode = SesameResultCode(rawValue: content[2...2].toUInt8())!
        self.data = content[3...].copyData
    }
}

// MARK: - Response
struct IRPubKeySymKeyPayload {
    var IR: String?
    var publicKey: String?
    var symmetricKey: String?
    
    static func fromData(_ buf: Data) -> IRPubKeySymKeyPayload? {
        let copyData = buf.copyData
        let ir = copyData[safeBound: 0...15]?.toHexString()
        let publicKey = copyData[safeBound: 16...79]?.toHexString()
        let symmetricKey = copyData[safeBound: 80...111]?.toHexString()
        let ficr = IRPubKeySymKeyPayload(IR: ir,
                              publicKey: publicKey,
                              symmetricKey: symmetricKey)
        return ficr
    }
}

struct Sesame2LoginResponsePayload {
    var systemTime: UInt32
    var fwVersion: UInt8
    var userCnt: UInt8
    var historyCnt: UInt8
    var flags: UInt8
    var mechSetting: CHSesame2MechSettings
    var mechStatus: Sesame2MechStatus

    static func fromData(_ buf: Data) -> Sesame2LoginResponsePayload? {
        if buf.count == 30 {
            //TODO For bad payload with autolock
            let offset = buf.indices.lowerBound
            let newBuf = buf[offset...offset + 7] + buf[offset + 10...offset + 29]
            return to(newBuf)
        }
        return to(buf)
    }

    func sesame2TimeFromNowTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970) - Int64(systemTime)
    }
}

public struct CHSesame2MechSettings {
    public  var lockPosition: Int16
    public  var unlockPosition: Int16
    public  var lockRangeMin: Int16
    public  var lockRangeMax: Int16
    public  var unlockRangeMin: Int16
    public  var unlockRangeMax: Int16

    static func fromData(_ buf: Data) -> CHSesame2MechSettings? {
        return to(buf)
    }

    func isConfigured() -> Bool {
        return lockPosition != INT16_MIN && unlockPosition != INT16_MIN
    }
}

public enum CHSesame2RetCodeType: UInt8 {
    case none = 0
    case success = 1
    case failEngage = 2
    case failMoveStart = 3
    case failMove = 4
    case failCheck = 5
    case failDetach = 6
    case failLoosen = 7
    case aborted = 8
    
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .success:
            return "success"
        case .failEngage:
            return "failEngage"
        case .failMoveStart:
            return "failMoveStart"
        case .failMove:
            return "failMove"
        case .failCheck:
            return "failCheck"
        case .failDetach:
            return "failDetach"
        case .failLoosen:
            return "failLoosen"
        case .aborted:
            return "aborted"
        }
    }
}

struct Sesame2MechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let target: Int16
    let position: Int16
    let retCode: UInt8
    let flags: UInt8
    var data: Data {
//        5d03 0080 fbff 00 12 B:10010     lock
//        5d03 0080 d200 00 14 B:10100     unlock
//        5d03 0080 0000 00 13 B:10011     lock
//        5d03 0080 d200 00 14 B:10100     unlock
//        5d03 0080 0200 00 92 B:10010010  lock
        battery.data + target.data + position.data + retCode.data + flags.data
    }
    var isClutchFailed: Bool { return flags & 1 > 0 }
    var isInLockRange: Bool { return flags & 2 > 0 }
    var isInUnlockRange: Bool { return flags & 4 > 0 }
    var isStop: Bool?{return nil}
    var isBatteryCritical: Bool { return flags & 32 > 0 }
    
    public func getBatteryVoltage() -> Float {
        return Float(battery) * 7.2 / 1023
    }

    static func fromData(_ buf: Data) -> Sesame2MechStatus? {
        return to(buf)
    }
    func ss5Adapter() -> Data {
        L.d("[s5 pro][iot] ss5Adapter <=")
        let battss5:UInt16 = UInt16((Int(battery) * 3600 / 1023))
        let positionss5:Int16 = Int16((Int(position) * 360 / 1024))
        return battss5.data + target.data + positionss5.data  + flags.data
    }
}

struct Sesame2VersionTag {
    typealias GitRevision = (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)

    var timestamp: Int32
    var revision: GitRevision

    var gitRevision: String {
        return withUnsafeBytes(of: revision, {
            String(decoding: $0, as: UTF8.self).remove("\0")
        })
    }

    static func fromData(_ buf: Data) -> Sesame2VersionTag? {
        return to(buf)
    }
}

struct Sesame2DFUConfiguration {
    var enabled: Int8

    public init(enabled: Bool) {
        self.enabled = enabled ? 1 : 0
    }

    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<Sesame2DFUConfiguration>.size)
    }
}

struct Sesame2Autolock {
    var seconds: Int16
    static func fromData(_ buf: Data) -> Sesame2Autolock? {
        return to(buf)
    }

    init(_ seconds: Int16) {
        self.seconds = seconds
    }

    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<Sesame2Autolock>.size)
    }
}

