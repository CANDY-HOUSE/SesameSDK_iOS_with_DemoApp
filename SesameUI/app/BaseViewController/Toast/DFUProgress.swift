//
//  DFUProgress.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/9/11.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import SesameSDK
import iOSDFULibrary

class TemporaryFirmwareUpdateClass: CHFirmwareUpdateInterface {
    func dfuSucceeded() {
        
    }
    
    weak var view: UIViewController?
    var alertView: UIAlertController
    var abortFunc: (() -> Void)?
    var isFinished: Bool = false
    var callBack:(_ from:String)->Void = {from in
        L.d("test 閉包")
    }

    init(_ mainView: UIViewController , callBack :@escaping (_ from:String)->Void ) {
        self.callBack =  callBack
        abortFunc = nil
        alertView = UIAlertController(title: "SesameOS Update".localStr, message: "Starting soon…".localStr, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Close".localStr, style: .default, handler: self.onAbortClick))
//                alertView.popoverPresentationController?.sourceView = mainView
//                alertView.popoverPresentationController?.sourceRect = mainView.frame
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
            alertView.message = "Initializing…".localStr
            abortFunc = abort
        }
    }

    func dfuStarted() {
        alertView.message = "Start".localStr
    }

    func dfuSucceed() {
        alertView.message = "Succeeded".localStr
        //        alertView.dismiss(animated: true, completion: nil)
        callBack("Succeed")
    }

    func dfuError(message: String) {
        alertView.message =  "Error".localStr + ":" + message 
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
            alertView.message = "Succeeded".localStr
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
        alertView.message =  "Error".localStr + ":" + message
    }
    
    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double,
                              avgSpeedBytesPerSecond: Double) {
        alertView.message = "\(progress)%"
    }
}
