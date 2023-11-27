//
//  NSError+.swift
//  Sesame2SDK
//
//  Created by YuHan Hsiao on 2020/7/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension NSError {
    static let parseError = NSError(domain: "Sesame2SDK", code: 480, userInfo: ["message": "Data parse failed"])
    static let noContent = NSError(domain: "Sesame2SDK", code: 204, userInfo: ["message": "Response 204"])
    static let sizeError = NSError(domain: "Sesame2SDK", code: 600, userInfo: ["message": "21 bytes limit"])
    static let blePoweredOff = NSError(domain: "CBCentralManager", code: 4, userInfo: ["message": "Bluetooth is off"])
    static let bleUnauthorized = NSError(domain: "CBCentralManager", code: 5, userInfo: ["message": "unauthorized"])
    static let registerError = NSError(domain: "Sesame2SDK", code: 500, userInfo: ["message": "registerError"])
    static let readIrErError = NSError(domain: "Sesame2SDK", code: 500, userInfo: ["message": "readIrErError"])
    static let bleInvalidAction = NSError(domain: "Sesame2SDK", code: 7, userInfo: ["message": "bleInvalidAction"])
    static let deviceStatusNotReceiveBLE = NSError(domain: "Sesame2SDK",
                                                   code: -2,
                                                   userInfo: ["message": "without receivedBle"])
    static let deviceNotLoggedIn = NSError(domain: "Sesame2SDK",
                                           code: -1,
                                           userInfo: ["message": "Sesame BLE unlogin"])
    static let peripheralEmpty = NSError(domain: "CBCentralManager",
                                         code: CHBluetoothCenter.shared.centralManager.state.rawValue,
                                         userInfo: ["message": "ble peripheral empty"])
    static let syncTimeError = NSError(domain: "SesameSDK", code: 0, userInfo: ["message": "sync time error"])
    static let deviceStatusNotReadyToRegister = NSError(domain: "SesameSDK", code: 0, userInfo: ["message": "not ready to register"])
    static let resetDeviceError = NSError(domain: "sesameSDK", code: 0, userInfo: ["message": "reset error"])
    static let getVersionTagFailed = NSError(domain: "SesameSDK", code: 0, userInfo: ["message": "getVersionTag failed"])
    static let sesameLockNotInLockRangeError = NSError(domain: "co.candyhouse.SesameSDK",
                                                      code: 0,
                                                      userInfo: ["message": "isInLockRange"])
    static let noSecretKeyError = NSError(domain: "com.sesame.sdk", code: 0, userInfo: ["message": "no secret key"])
    static let iotVerifyError = NSError(domain: "sesameSDK", code: 0, userInfo: ["message": "IoT vefify failed"])
    static let noDataError = NSError(domain: "sesame2", code: 0, userInfo: ["message": "no data"])
}


 
