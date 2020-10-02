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
    fileprivate var sesame2: CHSesame2! {
        didSet {
            sesame2?.delegate = self
        }
    }
    private var dfuHelper: DFUHelper?
    
    // MARK: startDFU
    func startDFU() {
        if sesame2.isRegistered {
            if sesame2.deviceStatus.loginStatus() == .logined {
                dfuSesame2(sesame2)
            } else {
                sesame2.connect { _ in
                    
                }
            }
        } else {
            if sesame2.deviceStatus == .readyToRegister {
                dfuSesame2(sesame2)
            } else {
                sesame2.connect { _ in
                    
                }
            }
        }
    }
    
    // MARK: complete
    private func complete() {
        addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Close".localized,
                                                      style: .default,
                                                      handler: nil))
        message = "co.candyhouse.sesame-sdk-test-app.Succeeded".localized
    }
    
    // MARK: didEnterBackground
    func didEnterBackground() {
        abortDFU()
    }
    
    // MARK: abortDFU
    private func abortDFU() {
        addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Close".localized,
                                                      style: .default,
                                                      handler: nil))
        message = "Aborted"
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    private func errorWithMessage(_ message: String) {
        self.message = "co.candyhouse.sesame-sdk-test-app.Error".localized + ":" + message
    }
}

// MARK: - CHSesame2Delegate
extension DFUAlertController: CHSesame2Delegate {
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status, shadowStatus: CHSesame2ShadowStatus?) {
        if !device.isRegistered,
           device.deviceStatus == .readyToRegister,
           dfuHelper?.isFinished == false {
            dfuSesame2(device)
        } else if device.isRegistered,
                  device.deviceStatus.loginStatus() == .logined,
                  dfuHelper?.isFinished == false {
            dfuSesame2(device)
        }
    }
    
    func dfuSesame2(_ sesame2: CHSesame2) {
        let filePath = DFUHelper.applicationDfuFilePath()!
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
        let dfuAlertController = DFUAlertController(title: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                    message: "co.candyhouse.sesame-sdk-test-app.StartingSoon".localized,
                                                    preferredStyle: .alert)
        dfuAlertController.sesame2 = sesame2
        return dfuAlertController
    }
}
