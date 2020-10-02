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
    static func applicationDfuFilePath() -> URL? {
        guard let filePath = Bundle.resourceBundle
            .url(forResource: nil,
                 withExtension: "zip",
                 subdirectory: "application_dfu") else {
                return nil
        }
        return filePath
    }
    
    static func applicationDfuFileName() -> String? {
        applicationDfuFilePath()?.lastPathComponent
    }
    
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
        
    }
    
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            break
        case .completed:
            isFinished = true
            clean()
        case .connecting:
            break
        case .disconnecting:
            break
        case .enablingDfuMode:
            break
        case .starting:
            break
        case .uploading:
            break
        case .validating:
            break
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
        delegate?.dfuProgressDidChange(for: part,
                                       outOf: totalParts,
                                       to: progress,
                                       currentSpeedBytesPerSecond: currentSpeedBytesPerSecond,
                                       avgSpeedBytesPerSecond: avgSpeedBytesPerSecond)
    }
}
