//
//  CHSesame5.swift
//  SesameSDK
//
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

public protocol CHSesame5Delegate: CHDeviceStatusDelegate {
    func onHistoryReceived(device: CHSesame5, result: Result<CHResultState<[CHSesame5History]>, Error>)
}
public extension CHSesame5Delegate {
    func onHistoryReceived(device: CHSesame5, result: Result<CHResultState<[CHSesame5History]>, Error>) {}
}
public protocol CHSesame5: CHSesameLock {
    var mechSetting: CHSesame5MechSettings? { get }
    var opsSetting: CHSesame5OpsSettings? { get }
    func toggle(result: @escaping (CHResult<CHEmpty>))
    func getVersionTag(result: @escaping (CHResult<String>))
    func lock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func toggle(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func getHistories(cursor: UInt?, _ result: @escaping CHResult<CHSesame5HistoryPayload>)
    func autolock(historytag:Data? ,delay: Int, result: @escaping (CHResult<Int>))
    func configureLockPosition(lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>))
    func magnet(result: @escaping (CHResult<CHEmpty>))
    func opSensorControl(delay: Int, result: @escaping (CHResult<Int>))
}

extension CHSesame5 {
    public func lock(result: @escaping (CHResult<CHEmpty>)) {
        lock(historytag: nil, result: result)
    }

    public func unlock(result: @escaping (CHResult<CHEmpty>)) {
        unlock(historytag: nil, result: result)
    }

    public func toggle(result: @escaping (CHResult<CHEmpty>)) {
        toggle(historytag: nil, result: result)
    }

    public func enableAutolock(delay: Int, result: @escaping (CHResult<Int>)) {
        autolock(historytag:nil ,delay: delay, result: result)
    }
}

public struct CHSesame5MechSettings {
  public var lockPosition: Int16
  public var unlockPosition: Int16
  public var autoLockSecond: Int16

    static func fromData(_ buf: Data) -> CHSesame5MechSettings? {
        let content = buf.copyData
        return  content.withUnsafeBytes({ $0.load(as: self) })
    }
    
    func isConfigured() -> Bool {
        return lockPosition != INT16_MIN && unlockPosition != INT16_MIN
    }
}

public struct CHSesame5OpsSettings {
    public var opsLockSecond: UInt16 //android的toShort:前兩個byte
    
    static func fromData(_ buf: Data) -> CHSesame5OpsSettings? {
        let content = buf.copyData
        return content.withUnsafeBytes({ $0.load(as: self) })
    }
}

struct CHSesame5LockPositionConfiguration {
    var lockTarget: Int16
    var unlockTarget: Int16

    init(lockTarget: Int16, unlockTarget: Int16, interval: Int16 = 150) {
        self.lockTarget = lockTarget
        self.unlockTarget = unlockTarget
    }

    mutating func toData() -> Data {
        return Data(bytes: &self, count: MemoryLayout<CHSesame5LockPositionConfiguration>.size)
    }
}

struct Sesame5Time {
    let time: UInt32

    static func fromData(_ buf: Data) -> Sesame5Time {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
