//
//  CHDevice+CHUserRegister.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/20.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

// MARK: - Register
extension CHDevice {
    func registerUserKey(_ result: @escaping (Result<NSNull, Error>)->Void) {
        if self is CHSesame2 {
            registerSesame2(result)
        } else if self is CHSesameBot {
            registerSesameBot(result)
        } else if self is CHSesameBike {
            registerBikeLock(result)
        } else if self is CHWifiModule2 {
            registerWifiModule2(result)
        }
    }
    
    private func registerSesame2(_ result: @escaping (Result<NSNull, Error>)->Void) {
        let sesame2: CHSesame2 = self as! CHSesame2
        sesame2.register(result: { registerResult in
            switch registerResult {
            case .success(_):
                Sesame2Store.shared.deletePropertyFor(sesame2)
                let encodedHistoryTag = Sesame2Store.shared.getHistoryTag()
                sesame2.setHistoryTag(encodedHistoryTag) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                sesame2.configureLockPosition(lockTarget: 0, unlockTarget: 256) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                sesame2.setDeviceName("co.candyhouse.sesame2.Sesame".localized)
                result(.success(NSNull()))
            case .failure(let error):
                result(.failure(error))
            }
        })
    }
    
    private func registerSesameBot(_ result: @escaping (Result<NSNull, Error>)->Void) {
        let sesameBot = self as! CHSesameBot
        sesameBot.register { registerResult in
            switch registerResult {
            case .success(_):
                Sesame2Store.shared.deletePropertyFor(sesameBot)
                let encodedHistoryTag = Sesame2Store.shared.getHistoryTag()
                sesameBot.setHistoryTag(encodedHistoryTag) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                sesameBot.setDeviceName("co.candyhouse.sesame2.SesameBot".localized)
                result(.success(NSNull()))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    private func registerBikeLock(_ result: @escaping (Result<NSNull, Error>)->Void) {
        let bikeLock = self as! CHSesameBike
        bikeLock.register { registerResult in
            switch registerResult {
            case .success(_):
                Sesame2Store.shared.deletePropertyFor(bikeLock)
                let encodedHistoryTag = Sesame2Store.shared.getHistoryTag()
                bikeLock.setHistoryTag(encodedHistoryTag) { _ in
                    
                }
                bikeLock.setDeviceName("co.candyhouse.sesame2.BikeLock".localized)
                result(.success(NSNull()))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    private func registerWifiModule2(_ result: @escaping (Result<NSNull, Error>)->Void) {
        let wifiModule2 = self as! CHWifiModule2
        wifiModule2.register { registerResult in
            switch registerResult {
            case .success(_):
                Sesame2Store.shared.deletePropertyFor(wifiModule2)
                wifiModule2.setDeviceName("co.candyhouse.sesame2.WifiModule2".localized)
                result(.success(NSNull()))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}

// MARK: - Reset
extension CHDevice {
    func dropUserKey(_ result: @escaping (Result<NSNull, Error>)->Void) {
        Sesame2Store.shared.deletePropertyFor(self)
        self.dropKey() { _ in }
        result(.success(NSNull()))
    }
    
    func resetUserKey(_ result: @escaping (Result<NSNull, Error>)->Void) {
        Sesame2Store.shared.deletePropertyFor(self)
        reset { resetResult in
            result(.success(NSNull()))
        }
    }
}
