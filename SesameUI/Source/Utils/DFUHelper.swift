//
//  DFUHelper.swift
//  sesame-sdk-test-app
//
//  Created by YuHan Hsiao on 2020/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import iOSDFULibrary
import CoreBluetooth

protocol DFUHelperDelegate: class {
    func dfuStateDidChange(to state: DFUState)
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String)
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double)
}

final class DFUCenter {
    static let shared = DFUCenter()
    
    let devices = [CHDevice]()
    var dfuHelpers = [String: DFUHelper]()
    
    func dfuDevice(_ device: CHDevice, delegate: DFUHelperDelegate) {
        if let device = device as? CHSesame2 {
            device.updateFirmware { result in
                switch result {
                case .success(let peripheral):
                    guard let peripheral = peripheral.data else { return }
                    let filePath = DFUHelper.sesame2ApplicationDfuFilePath(device)!
                    let dfuData = try! Data(contentsOf: filePath)
                    let dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)!
                    self.dfuHelpers[device.deviceId.uuidString] = dfuHelper
                    dfuHelper.delegate = delegate
                    dfuHelper.start(.application)
                case .failure(_):
                    delegate.dfuError(.unsupportedResponse, didOccurWithMessage: "")
                }
            }
        } else if let device = device as? CHSesameBot {
            device.updateFirmware { result in
                switch result {
                case .success(let peripheral):
                    guard let peripheral = peripheral.data else { return }
                    let filePath = DFUHelper.sesameBotApplicationDfuFilePath()!
                    let dfuData = try! Data(contentsOf: filePath)
                    let dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)!
                    self.dfuHelpers[device.deviceId.uuidString] = dfuHelper
                    dfuHelper.delegate = delegate
                    dfuHelper.start(.application)
                case .failure(_):
                    break
                }
            }
        } else if let device = device as? CHSesameBike {
            device.updateFirmware { result in
                switch result {
                case .success(let peripheral):
                    guard let peripheral = peripheral.data else { return }
                    let filePath = DFUHelper.bikeLockApplicationDfuFilePath()!
                    let dfuData = try! Data(contentsOf: filePath)
                    let dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)!
                    self.dfuHelpers[device.deviceId.uuidString] = dfuHelper
                    dfuHelper.delegate = delegate
                    dfuHelper.start(.application)
                case .failure(_):
                    break
                }
            }
        }
    }
    
    func confirmDFUDeletegate(_ delegate: DFUHelperDelegate, forDevice device: CHDevice) {
        if let dfuHelper = self.dfuHelpers[device.deviceId.uuidString] {
            dfuHelper.delegate = delegate
        }
    }
    
    func removeDFUDelegateForDevice(_ device: CHDevice) {
        if let dfuHelper = self.dfuHelpers[device.deviceId.uuidString] {
            dfuHelper.delegate = nil
        }
    }
}

final class DFUHelper {
    let peripheral: CBPeripheral
    let zipData: Data
    weak var delegate: DFUHelperDelegate?
    fileprivate(set) var isFinished: Bool = true
    
    fileprivate var dfuController: DFUServiceController?
    
    lazy fileprivate var dfuServiceInitiator: DFUServiceInitiator = {
        let dfuService = DFUServiceInitiator()
        dfuService.forceDfu = UserDefaults.standard.bool(forKey: "dfu_force_dfu")
        dfuService.packetReceiptNotificationParameter = UInt16(UserDefaults.standard.integer(forKey: "dfu_number_of_packets"))
        dfuService.logger = self
        dfuService.delegate = self
        dfuService.progressDelegate = self
        dfuService.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        return dfuService
    }()
    
    init?(peripheral: CBPeripheral,
                 zipData: Data,
                 observer: DFUHelperDelegate? = nil) {
        self.peripheral = peripheral
        self.zipData = zipData
        self.delegate = observer
    }
    
    func start(_ type: DFUFirmwareType = .application) {
        isFinished = false
        guard let firmware = DFUFirmware(zipFile: zipData, type: type) else {
            L.d("No firmware")
            abort()
            delegate?.dfuError(DFUError.fileInvalid,
                               didOccurWithMessage: "Dfu error")
            return
        }
        
        guard let dfuController = dfuServiceInitiator.with(firmware: firmware).start(target: peripheral) else {
            L.d("Start peripheral failed")
            return
        }
        self.dfuController = dfuController
    }
    
    func pause() {
        guard let dfuController = dfuController else {
            L.d("Pause: DfuController is nil")
            return
        }
        dfuController.pause()
    }
    
    func resume() {
        guard let dfuController = dfuController else {
            L.d("Resume: DfuController is nil")
            return
        }
        dfuController.resume()
    }
    
    func restart() {
        isFinished = false
        guard let dfuController = dfuController else {
            L.d("Restart: DfuController is nil")
            return
        }
        dfuController.restart()
    }
    
    @discardableResult
    func abort() -> Bool {
        guard let dfuController = dfuController else {
            L.d("Abord: DfuController is nil")
            return false
        }
        let result = dfuController.abort()
        clean()
        return result
    }
    
    private func clean() {
        dfuController = nil
    }
}

extension DFUHelper {
    // MARK: - Switch
    static func sesameBotApplicationDfuFilePath() -> URL? {
        guard let filePath = Bundle.resourceBundle
            .url(forResource: nil,
                 withExtension: "zip",
                 subdirectory: "sesame_bot_application_dfu") else {
                return nil
        }
        return filePath
    }
    
    static func sesameBotApplicationDfuFileName() -> String? {
        sesameBotApplicationDfuFilePath()?.lastPathComponent
    }
    
    // MARK: - Sesame2
    static func sesame2ApplicationDfuFilePath(_ sesame2: CHSesame2) -> URL? {
        let subdirectory = sesame2.productModel == CHProductModel.sesame2 ? "sesame2_application_dfu" : "sesame4_application_dfu"
        guard let filePath = Bundle.resourceBundle
            .url(forResource: nil,
                 withExtension: "zip",
                 subdirectory: subdirectory) else {
                return nil
        }
        return filePath
    }
    
    static func sesame2ApplicationDfuFileName(_ sesame2: CHSesame2) -> String? {
        sesame2ApplicationDfuFilePath(sesame2)?.lastPathComponent
    }
    
    // MARK: - BikeLock
    static func bikeLockApplicationDfuFilePath() -> URL? {
        guard let filePath = Bundle.resourceBundle
            .url(forResource: nil,
                 withExtension: "zip",
                 subdirectory: "bike_lock_application_dfu") else {
                return nil
        }
        return filePath
    }
    
    static func bikeLockApplicationDfuFileName() -> String? {
        bikeLockApplicationDfuFilePath()?.lastPathComponent
    }
    
    // MARK: - Bootloader
    static func bootloaderDfuFilePath() -> URL? {
        guard let filePath = Bundle.resourceBundle
            .url(forResource: nil,
                 withExtension: "zip",
                 subdirectory: "bootloader_dfu") else {
                return nil
        }
        return filePath
    }
    
    static func bootloaderDfuFileName() -> String? {
        bootloaderDfuFilePath()?.lastPathComponent
    }
}

extension DFUHelper: LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    func logWith(_ level: LogLevel, message: String) {
        L.d("DFUHelper", message)
    }
    
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            L.d("DFUHelper", "aborted")
        case .completed:
            isFinished = true
            clean()
            L.d("DFUHelper", "completed")
        case .connecting:
            L.d("DFUHelper", "connecting")
        case .disconnecting:
            L.d("DFUHelper", "disconnecting")
        case .enablingDfuMode:
            L.d("DFUHelper", "enablingDfuMode")
        case .starting:
            L.d("DFUHelper", "starting")
        case .uploading:
            L.d("DFUHelper", "uploading")
        case .validating:
            L.d("DFUHelper", "validating")
        }
        delegate?.dfuStateDidChange(to: state)
    }
    
    func dfuError(_ error: DFUError,
                         didOccurWithMessage message: String) {
        delegate?.dfuError(error,
                           didOccurWithMessage: message)
        isFinished = true
        clean()
    }
    
    func dfuProgressDidChange(for part: Int,
                                     outOf totalParts: Int,
                                     to progress: Int,
                                     currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        L.d("DFUHelper", "dfuProgressDidChange", progress)
        
        delegate?.dfuProgressDidChange(for: part,
                                       outOf: totalParts,
                                       to: progress,
                                       currentSpeedBytesPerSecond: currentSpeedBytesPerSecond,
                                       avgSpeedBytesPerSecond: avgSpeedBytesPerSecond)
    }
}
