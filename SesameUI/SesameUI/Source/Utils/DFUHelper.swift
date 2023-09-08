//
//  DFUHelper.swift
//  sesame-sdk-test-app
//
//  Created by YuHan Hsiao on 2020/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import NordicDFU
import CoreBluetooth

protocol DFUHelperDelegate: AnyObject {
    func dfuStateDidChange(to state: DFUState)
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String)
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double)
}

/// DFUCenter,  保存 dfu 物件，提供當前 dfu 進度
final class DFUCenter {
    static let shared = DFUCenter()
    
    let devices = [CHDevice]()
    var dfuHelpers = [String: DFUHelper]()
    
    func dfuDevice(_ device: CHDevice, delegate: DFUHelperDelegate) {
        device.updateFirmware { result in
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else { return }
                let dfuData = try! Data(contentsOf: DFUHelper.getDfuFilePath(device))
                let dfuHelper = DFUHelper(peripheral: peripheral, zipData: dfuData)!
                self.dfuHelpers[device.deviceId.uuidString] = dfuHelper
                dfuHelper.delegate = delegate
                dfuHelper.start(.application)
            case .failure(_):
                delegate.dfuError(.unsupportedResponse, didOccurWithMessage: "")
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

/// 第三方 dfu library wrapper
final class DFUHelper { // [joi todo check]
    let peripheral: CBPeripheral
    let zipData: Data
    weak var delegate: DFUHelperDelegate?
    fileprivate(set) var isFinished: Bool = true
    
    fileprivate var dfuController: DFUServiceController?
    
    lazy fileprivate var dfuServiceInitiator: DFUServiceInitiator = {
        let dfuService = DFUServiceInitiator()
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

        guard let firmware = try? DFUFirmware(zipFile: zipData, type: type) else {
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
    
    deinit {
        L.d("updateFirmware", "deinit")
    }
}

// MARK: Device get name & path
extension DFUHelper {
    // MARK: - Devices
    static func getDfuFilePath(_ device: CHDevice) -> URL {
        return  device.getFirZip()
    }

    static func getDfuFileName(_ device: CHDevice) -> String {
        device.getFirZip().lastPathComponent
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
