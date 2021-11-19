//
//  DFUAlertController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import iOSDFULibrary

class DFUAlertController: UIAlertController {
    fileprivate var dfuType: SesameDeviceType!
    
    fileprivate var sesame2: CHSesame2! {
        didSet {
            sesame2?.delegate = self
        }
    }
    
    fileprivate var sesameBot: CHSesameBot! {
        didSet {
            sesameBot?.delegate = self
        }
    }
    
    fileprivate var bikeLock: CHSesameBike! {
        didSet {
            bikeLock?.delegate = self
        }
    }
    
    private var dfuHelper: DFUHelper?
    
    // MARK: startDFU
    func startDFU() {
        
        switch dfuType {
        case .sesame2, .sesame4:
            if sesame2.isRegistered {
                if sesame2.deviceStatus.loginStatus == .logined {
                    dfuSesame2(sesame2)
                } else {
                    sesame2.connect() { _ in
                        
                    }
                }
            } else {
                if sesame2.deviceStatus == .readyToRegister() {
                    dfuSesame2(sesame2)
                } else {
                    sesame2.connect() { _ in
                        
                    }
                }
            }
        case .sesameBot:
            if sesameBot.isRegistered {
                if sesameBot.deviceStatus.loginStatus == .logined {
                    dfuSesameBot(sesameBot)
                } else {
                    sesameBot.connect() { _ in
                        
                    }
                }
            } else {
                if sesameBot.deviceStatus == .readyToRegister() {
                    dfuSesameBot(sesameBot)
                } else {
                    sesameBot.connect() { _ in
                        
                    }
                }
            }
        case .bikeLock:
            if bikeLock.isRegistered {
                if bikeLock.deviceStatus.loginStatus == .logined {
                    dfuBikeLock(bikeLock)
                } else {
                    bikeLock.connect() { _ in
                        
                    }
                }
            } else {
                if bikeLock.deviceStatus == .readyToRegister() {
                    dfuBikeLock(bikeLock)
                } else {
                    bikeLock.connect() { _ in
                        
                    }
                }
            }
        case .wifiModule2:
            break
        case .none:
            break
        }
    }
    
    // MARK: complete
    private func complete() {
        addAction(UIAlertAction(title: "co.candyhouse.sesame2.Close".localized,
                                                      style: .default,
                                                      handler: nil))
        message = "co.candyhouse.sesame2.Succeeded".localized
    }
    
    // MARK: didEnterBackground
    func didEnterBackground() {
        abortDFU()
    }
    
    // MARK: abortDFU
    private func abortDFU() {
        addAction(UIAlertAction(title: "co.candyhouse.sesame2.Close".localized,
                                                      style: .default,
                                                      handler: nil))
        message = "Aborted"
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    private func errorWithMessage(_ message: String) {
        self.message = "co.candyhouse.sesame2.Error".localized + ":" + message
    }
}

extension DFUAlertController: CHSesame2StatusDelegate {
    func onBleDeviceStatusChanged(device: CHSesameLock, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if !device.isRegistered,
           device.deviceStatus == .readyToRegister(),
           dfuHelper?.isFinished != true,
           let sesame2 = device as? CHSesame2 {
            dfuSesame2(sesame2)
        } else if device.isRegistered,
                  device.deviceStatus.loginStatus == .logined,
                  dfuHelper?.isFinished != true,
                  let sesame2 = device as? CHSesame2 {
            dfuSesame2(sesame2)
        } else if !device.isRegistered,
                  device.deviceStatus == .readyToRegister(),
                  dfuHelper?.isFinished != true,
                  let sesameBot = device as? CHSesameBot {
            dfuSesameBot(sesameBot)
        } else if device.isRegistered,
                  device.deviceStatus.loginStatus == .logined,
                  dfuHelper?.isFinished != true,
                  let sesameBot = device as? CHSesameBot {
            dfuSesameBot(sesameBot)
        } else if !device.isRegistered,
                  device.deviceStatus == .readyToRegister(),
                  dfuHelper?.isFinished != true,
                  let biekLock = device as? CHSesameBike {
            dfuBikeLock(biekLock)
        } else if device.isRegistered,
                  device.deviceStatus.loginStatus == .logined,
                  dfuHelper?.isFinished != true,
                  let biekLock = device as? CHSesameBike {
            dfuBikeLock(biekLock)
        }
    }
}

// MARK: - CHSesame2Delegate
extension DFUAlertController {
    func dfuSesame2(_ sesame2: CHSesame2) {
        let filePath = DFUHelper.sesame2ApplicationDfuFilePath(sesame2)!
        let dfuData = try! Data(contentsOf: filePath)
        
        sesame2.updateFirmware { result in
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    return
                }
                self.dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)
                self.dfuHelper?.delegate = self
                self.dfuHelper?.start(.application)
            case .failure(_):
                break
            }
        }
    }
    
    func dfuSesameBot(_ switchDevice: CHSesameBot) {
        let filePath = DFUHelper.sesameBotApplicationDfuFilePath()!
        let dfuData = try! Data(contentsOf: filePath)
        
        switchDevice.updateFirmware { result in
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    return
                }
                self.dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)
                self.dfuHelper?.delegate = self
                self.dfuHelper?.start(.application)
            case .failure(_):
                break
            }
        }
    }
    
    func dfuBikeLock(_ device: CHSesameBike) {
        let filePath = DFUHelper.bikeLockApplicationDfuFilePath()!
        let dfuData = try! Data(contentsOf: filePath)
        
        device.updateFirmware { result in
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    return
                }
                self.dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)
                self.dfuHelper?.delegate = self
                self.dfuHelper?.start(.application)
            case .failure(_):
                break
            }
        }
    }
}

// MARK: - DFUHelperDelegate
extension DFUAlertController: DFUHelperDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .starting:
            break
        case .completed:
            complete()
        case .aborted:
            abortDFU()
        default:
            break
        }
    }
    
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String) {
        errorWithMessage(":\(message)")
    }
    
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        message = "\(progress)%"
    }
}

// MARK: - Designated initializer
extension DFUAlertController {
    static func instanceWithSesame2(_ sesame2: CHSesame2) -> DFUAlertController {
        let dfuAlertController = DFUAlertController(title: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                    message: "co.candyhouse.sesame2.StartingSoon".localized,
                                                    preferredStyle: .alert)
        dfuAlertController.dfuType = .sesame2
        dfuAlertController.sesame2 = sesame2
        return dfuAlertController
    }
    
    static func instanceWithSwitch(_ switchDevice: CHSesameBot) -> DFUAlertController {
        let dfuAlertController = DFUAlertController(title: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                    message: "co.candyhouse.sesame2.StartingSoon".localized,
                                                    preferredStyle: .alert)
        dfuAlertController.dfuType = .sesameBot
        dfuAlertController.sesameBot = switchDevice
        return dfuAlertController
    }
    
    static func instanceWithBikeLock(_ bikeLock: CHSesameBike) -> DFUAlertController {
        let dfuAlertController = DFUAlertController(title: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                    message: "co.candyhouse.sesame2.StartingSoon".localized,
                                                    preferredStyle: .alert)
        dfuAlertController.dfuType = .bikeLock
        dfuAlertController.bikeLock = bikeLock
        return dfuAlertController
    }
}

extension DFUAlertController: CHSesame2Delegate, CHSesameBotDelegate, CHSesameBikeDelegate {
    
}
