//
//  CHSesame2.swift
//  SesameSDK
//
//  Created by tse on 2020/7/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
import CoreBluetooth

public protocol CHSesame2Delegate: CHDeviceStatusDelegate {
    func onHistoryReceived(device: CHSesame2, result: Result<CHResultState<[CHSesame2History]>, Error>)
}
public extension CHSesame2Delegate {
    func onHistoryReceived(device: CHSesame2, result: Result<CHResultState<[CHSesame2History]>, Error>) {}
}

public protocol CHSesame2: CHSesameLock {
    var deviceStatus: CHDeviceStatus { get set }
    var mechSetting: CHSesame2MechSettings? { get }
    func toggle(result: @escaping (CHResult<CHEmpty>))
    func getVersionTag(result: @escaping (CHResult<String>))
    func getAutolockSetting(result: @escaping (CHResult<Int>))
    func lock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func toggle(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func getHistories(cursor: UInt?, _ result: @escaping CHResult<CHSesameHistoryPayload>)
    func enableAutolock(historytag:Data? ,delay: Int, result: @escaping (CHResult<Int>))
    func configureLockPosition(historytag:Data? ,lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>))
}

extension CHSesame2 {
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
        enableAutolock(historytag:nil ,delay: delay, result: result)
    }

    public func configureLockPosition(lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>)) {
        configureLockPosition(historytag: nil,lockTarget: lockTarget, unlockTarget: unlockTarget, result: result)
    }
}

