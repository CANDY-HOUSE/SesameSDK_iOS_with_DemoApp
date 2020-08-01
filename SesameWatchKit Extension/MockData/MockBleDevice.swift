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
    func getBatteryPrecentage() -> Int {
        0
    }

    func getBatteryVoltage() -> Float {
        1000.0
    }
    
    func getPosition() -> Int64? {
        nil
    }
    
    func isInLockRange() -> Bool? {
           nil
       }
    
    func isInUnlockRange() -> Bool? {
           nil
       }
}

struct MockCHSesameMechSettings: CHSesame2MechSettings {
    func getLockPosition() -> Int64? {
           nil
       }
    
    func getLockMinPosition() -> Int64? {
           nil
       }
    
    func getLockMaxPosition() -> Int64? {
           nil
       }
    
    func getUnlockPosition() -> Int64? {
           nil
       }
    
    func getUnlockMinPosition() -> Int64? {
           nil
       }
    
    func getUnlockMaxPosition() -> Int64? {
           nil
       }
    
    func isConfigured() -> Bool {
        true
    }
}

final class MockBleDevice: CHSesame2 {
    func dropKey(result: @escaping (CHResult<CHEmpty>)) {
        
    }

    var deviceId: UUID! = UUID()
    var bleAdvParameter: CHSesame2BleAdvParameter?
    var delegate: CHSesame2Delegate?
    
    var rssi: NSNumber? = NSNumber(value: 100)
    
    var isRegistered: Bool = true
    
    var deviceStatus: CHSesame2Status = .locked
    
    var mechStatus: CHSesame2MechStatus?
    
    var mechSetting: CHSesame2MechSettings?
    
    var intention: CHSesame2Intention = .idle
    
    func lock(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func unlock(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func toggle(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func connect(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func disconnect(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func registerSesame2(_ result: @escaping CHResult<CHEmpty>) {
        
    }
    
    func resetSesame2(result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func configureLockPosition(lockTarget: Int16, unlockTarget: Int16, result: @escaping (CHResult<CHEmpty>)) {
        
    }
    
    func getAutolockSetting(result: @escaping (CHResult<Int>)) {
        
    }
    
    func enableAutolock(delay: Int, result: @escaping (CHResult<Int>)) {
        
    }
    
    func disableAutolock(result: @escaping (CHResult<Int>)) {
        
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
    
    func dropKey() {
        
    }
    
    func getKey() -> String? {
        nil
    }
    
    func getHistories(page: UInt, _ result: @escaping CHResult<[CHSesame2History]>) {
        
    }
    
    func getAdvInter(_ callback: @escaping CHResult<[Int]>) {
        
    }
    
    func getTxPower(_ callback: @escaping CHResult<[Int]>) {
        
    }
    
    func getBleAdvParameter(_ result: @escaping CHResult<CHSesame2BleAdvParameter>) {
        
    }
    
    func updateBleAdvParameter(interval: UInt16, txPower: Int8,
                               _ result: @escaping CHResult<CHSesame2BleAdvParameter>) {
        
    }
}
