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

public protocol DFUHelperObserver {
    func dfuStateDidChange(to state: DFUState)
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String)
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double)
}

public protocol DFUHelper {
    init?(peripheral: CBPeripheral, zipData: Data, observer: DFUHelperObserver?)
    func start()
    func pause()
    func resume()
    func restart()
    @discardableResult func abort() -> Bool
    var observer: DFUHelperObserver? { set get }
}

final public class CHDFUHelper: DFUHelper {
    let peripheral: CBPeripheral
    let zipData: Data
    public var observer: DFUHelperObserver?
    
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
    
    public init?(peripheral: CBPeripheral,
                 zipData: Data,
                 observer: DFUHelperObserver? = nil) {
        self.peripheral = peripheral
        self.zipData = zipData
        self.observer = observer
    }
    
    public func start() {
        guard let firmware = DFUFirmware(zipFile: zipData, type: .application) else {
            L.d("No firmware")
            return
        }
        
        guard let dfuController = dfuServiceInitiator.with(firmware: firmware).start(target: peripheral) else {
            L.d("Start peripheral failed")
            return
        }
        
        self.dfuController = dfuController
    }
    
    public func pause() {
        guard let dfuController = dfuController else {
            L.d("Pause: DfuController is nil")
            return
        }
        dfuController.pause()
    }
    
    public func resume() {
        guard let dfuController = dfuController else {
            L.d("Resume: DfuController is nil")
            return
        }
        dfuController.resume()
    }
    
    public func restart() {
        guard let dfuController = dfuController else {
            L.d("Restart: DfuController is nil")
            return
        }
        dfuController.restart()
    }
    
    @discardableResult
    public func abort() -> Bool {
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

extension CHDFUHelper: LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    public func logWith(_ level: LogLevel, message: String) {
        
    }
    
    public func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            break
        case .completed:
            defer {
                clean()
            }
            break
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
        observer?.dfuStateDidChange(to: state)
    }
    
    public func dfuError(_ error: DFUError,
                         didOccurWithMessage message: String) {
        defer {
            clean()
        }
        observer?.dfuError(error,
                           didOccurWithMessage: message)
    }
    
    public func dfuProgressDidChange(for part: Int,
                                     outOf totalParts: Int,
                                     to progress: Int,
                                     currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        observer?.dfuProgressDidChange(for: part,
                                       outOf: totalParts,
                                       to: progress,
                                       currentSpeedBytesPerSecond: currentSpeedBytesPerSecond,
                                       avgSpeedBytesPerSecond: avgSpeedBytesPerSecond)
    }
}
