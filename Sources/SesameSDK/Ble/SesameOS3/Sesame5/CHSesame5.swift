//
//  CHSesame5.swift
//  SesameSDK
//
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

public let CHDeviceUnsetSensorDetectInterval: Int16 = -1

// https://github.com/CANDY-HOUSE/API_document/blob/master/SesameOS3/4_history.md
public protocol CHSesame5Delegate: CHDeviceStatusDelegate {
    func onHistoryReceived(device: CHSesame5, result: Result<CHResultState<Data>, Error>)
    func onSensorDetectIntervalReceive(device: CHSesame5, intervalMs: Int16)
    func onLockUnlockSwitchPointReceive(device: CHSesame5, point: Int16)
}
public extension CHSesame5Delegate {
    func onHistoryReceived(device: CHSesame5, result: Result<CHResultState<Data>, Error>) {}
    func onSensorDetectIntervalReceive(device: CHSesame5, intervalMs: Int16) {}
    func onLockUnlockSwitchPointReceive(device: CHSesame5, point: Int16) {}
}
public protocol CHSesame5: CHSesameLock {
    var mechSetting: CHSesame5MechSettings? { get }
    var opsSetting: CHSesame5OpsSettings? { get }
    var sensorDetectIntervalMs: Int16 { get }
    var lockUnlockSwitchPoint: Int16 { get }
    var hasLockUnlockSwitchPointSetting: Bool { get }
    func getVersionTag(result: @escaping (CHResult<String>))
    func lock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func toggle(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func autolock(historytag:Data? ,delay: Int, result: @escaping (CHResult<Int>))
    func configureLockPosition(lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>))
    func magnet(result: @escaping (CHResult<CHEmpty>))
    func opSensorControl(delay: Int, result: @escaping (CHResult<Int>))
    func setSensorDetectInterval(intervalMs: Int16, result: @escaping (CHResult<CHEmpty>))
    func setLockUnlockSwitchPoint(point: Int16, result: @escaping (CHResult<CHEmpty>))
    func sendAdvProductTypeCommand(data: Data,result: @escaping (CHResult<CHEmpty>))
}

extension CHSesame5 {
    public func lock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>)) {
        
        lock(historytag: historytag, result: result)
    }

    public func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>)) {
        unlock(historytag: historytag, result: result)
    }

    public func toggle(historytag:Data? ,result: @escaping (CHResult<CHEmpty>)) {
        toggle(historytag: historytag, result: result)
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
//        return to(buf)
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
