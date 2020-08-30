//
//  DFUProgress.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/9/11.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import iOSDFULibrary

public protocol CHFirmwareUpdateInterface: class {
    func dfuInitialized(abort: @escaping () -> Void)
    func dfuStarted()
    func dfuSucceeded()
    func dfuError(message: String)
    func dfuProgressDidChange(progress: Int)
}

class TemporaryFirmwareUpdateClass: CHFirmwareUpdateInterface {
    func dfuSucceeded() {
        
    }
    
    weak var view: UIViewController?
    var alertView: UIAlertController
    var abortFunc: (() -> Void)?
    var isFinished: Bool = false
    var callBack:(_ from:String)->Void = {from in
        
    }

    init(_ mainView: UIViewController , callBack :@escaping (_ from:String)->Void ) {
        self.callBack =  callBack
        abortFunc = nil
        alertView = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                      message: "co.candyhouse.sesame-sdk-test-app.StartingSoon".localized,
                                      preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Close".localized,
                                          style: .default,
                                          handler: self.onAbortClick))
        mainView.present(self.alertView, animated: true, completion: nil)
    }

    func onAbortClick(_ btn: UIAlertAction) {
        if isFinished == false {
            isFinished = true
            if let abortFunc = abortFunc {
                abortFunc()
            }
        }
    }

    func dfuInitialized(abort: @escaping () -> Void) {
        if isFinished {
            abort()
        } else {
            alertView.message = "co.candyhouse.sesame-sdk-test-app.Initializing".localized
            abortFunc = abort
        }
    }

    func dfuStarted() {
        alertView.message = "co.candyhouse.sesame-sdk-test-app.Start".localized
    }

    func dfuSucceed() {
        alertView.message = "co.candyhouse.sesame-sdk-test-app.Succeeded".localized
        callBack("Succeed")
    }

    func dfuError(message: String) {
        alertView.message =  "co.candyhouse.sesame-sdk-test-app.Error".localized + ":" + message
    }

    func dfuProgressDidChange(progress: Int) {
        alertView.message = "\(progress)%"
    }
}

extension TemporaryFirmwareUpdateClass: DFUHelperObserver {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            break
        case .completed:
            alertView.message = "co.candyhouse.sesame-sdk-test-app.Succeeded".localized
            callBack("Succeed")
            isFinished = true
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
    }
    
    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String) {
        alertView.message =  "co.candyhouse.sesame-sdk-test-app.Error".localized + ":" + message
    }
    
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double,
                              avgSpeedBytesPerSecond: Double) {
        alertView.message = "\(progress)%"
    }
}
