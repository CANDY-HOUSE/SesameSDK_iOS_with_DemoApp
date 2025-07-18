//
//  CHSesameBot.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

public protocol CHSesameBotDelegate: CHDeviceStatusDelegate {
}

public extension CHSesameBotDelegate {
}

public protocol CHSesameBot: CHSesameLock {

    var mechSetting: CHSesameBotMechSettings? { get set }
    func toggle(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func lock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func click(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))
    func updateSetting(historytag: Data?, setting: CHSesameBotMechSettings, result: @escaping CHResult<CHEmpty>)
}

extension CHSesameBot {
    public func toggle(result: @escaping (CHResult<CHEmpty>)) {
        toggle(historytag: nil, result: result)
    }
    public func lock(result: @escaping (CHResult<CHEmpty>)) {
        lock(historytag: nil, result: result)
    }
    public func click(result: @escaping (CHResult<CHEmpty>)) {
        click(historytag: nil, result: result)
    }
    public func unlock(result: @escaping (CHResult<CHEmpty>)) {
        unlock(historytag: nil, result: result)
    }
    public func updateSetting(setting: CHSesameBotMechSettings, result: @escaping CHResult<CHEmpty>) {
        updateSetting(historytag: nil, setting: setting, result: result)
    }
}

