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
    func dfuInitializedWithAbortHandler(_ abort: @escaping () -> Void)
    func dfuStarted()
    func dfuSucceeded()
    func dfuError(message: String)
    func dfuProgressDidChange(progress: Int)
}

class DFUAlertController: UIAlertController {
    var willEnterBackground: (()->Void)?
}

class DFUIndicator: CHFirmwareUpdateInterface {
    func dfuSucceeded() {
        
    }
    
    static let shared = DFUIndicator()
    weak var presentingViewController: UIViewController? {
        didSet {
            isFinished = false
            alertView = DFUAlertController(title: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                           message: "co.candyhouse.sesame-sdk-test-app.StartingSoon".localized,
                                           preferredStyle: .alert)
            alertView.popoverPresentationController?.sourceView = self.presentingViewController?.view
            alertView.willEnterBackground = { [weak self] in
                if self?.isFinished == false {
                    self?.isFinished = true
                    if let abortFunc = self?.abortFunc {
                        self?.alertView.message = "Aborted"
                        self?.alertView.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Close".localized,
                                                          style: .default,
                                                          handler: self?.onAbortClick))
                        abortFunc()
                    }
                }
            }
            guard let alertView = self.alertView else {
                return
            }
            presentingViewController?.present(alertView, animated: true, completion: nil)
        }
    }
    var alertView: DFUAlertController!
    var abortFunc: (() -> Void)?
    var isFinished: Bool = false
    var callBack:(_ from:String)->Void = {from in
        
    }
    
    private init() {
        self.abortFunc = nil
    }

    init(_ mainView: UIViewController , callBack :@escaping (_ from:String)->Void ) {
        self.callBack = callBack
        self.abortFunc = nil
        self.presentingViewController = mainView
    }

    func onAbortClick(_ btn: UIAlertAction) {
        if isFinished == false {
            isFinished = true
            if let abortFunc = abortFunc {
                abortFunc()
            }
        }
    }

    func dfuInitializedWithAbortHandler(_ abort: @escaping () -> Void) {
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

extension DFUIndicator: DFUHelperObserver {
    
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .aborted:
            break
        case .completed:
            alertView.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Close".localized,
                                              style: .default,
                                              handler: self.onAbortClick))
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
