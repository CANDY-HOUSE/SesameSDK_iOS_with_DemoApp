//
//  MockBleDevice.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/6.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameWatchKitSDK
import CoreBluetooth

struct MockCHSesameMechStatus: CHSesame2MechStatus {
    func getBatteryVoltage() -> Float {
        0
    }
    
    func getBatteryPrecentage() -> Int {
        0
    }
    
    var position: Int16 = 0
    
    var isInLockRange: Bool = true
    
    var isInUnlockRange: Bool = true
    
    func retCodeType() -> Sesame2RetCodeType {
        .none
    }
    
    var isClutchFailed: Bool = false
}

struct MockCHSesameMechSettings: CHSesame2MechSettings {
    var lockPosition: Int16 = 180
    
    var unlockPosition: Int16 = 90
    
    func isConfigured() -> Bool {
        true
    }
}

class MockBleDevice: CHSesame2 {
    var deviceShadowStatus: CHSesame2ShadowStatus?

    func disableAutolock(historytag: Data?, result: @escaping (CHResult<Int>)) {
        
    }
    
    func enableAutolock(historytag: Data?, delay: Int, result: @escaping (CHResult<Int>)) {
        
    }
    
    func updateBleAdvParameter(historytag: Data?, interval: Double, txPower: Int8, _ result: @escaping CHResult<Sesame2BleAdvParameter>) {
        
    }
    
    func configureLockPosition(historytag: Data?, lockTarget: Int16, unlockTarget: Int16, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func toggle(historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func lock(historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    var deviceId: UUID! = UUID()
    
    var delegate: CHSesame2Delegate?
    
    var rssi: NSNumber?
    
    var txPowerLevel: Int?
    
    var isRegistered: Bool = true
    
    var deviceStatus: CHSesame2Status = .locked
    
    var mechStatus: CHSesame2MechStatus? = MockCHSesameMechStatus()
    
    var mechSetting: CHSesame2MechSettings? = MockCHSesameMechSettings()
    
    var intention: CHSesame2Intention = .locking
    
    func connect(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func disconnect(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func registerSesame2(_ result: @escaping CHResult<CHEmpty>) {
        
    }
    
    func resetSesame2(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func getAutolockSetting(result: @escaping (CHResult<Int>)) {
        
    }
    
    func updateFirmware(_ result: @escaping CHResult<CBPeripheral?>) {
        
    }
    
    func getVersionTag(result: @escaping (CHResult<String>)) {
        
    }
    
    func setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func getHistoryTag() -> Data? {
        nil
    }
    
    func dropKey(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func getKey() -> String? {
        nil
    }
    
    func getHistories(page: UInt, _ result: @escaping CHResult<[CHSesame2History]>) {
        
    }
    
    func getBleAdvParameter(_ result: @escaping CHResult<Sesame2BleAdvParameter>) {
        
    }
}
