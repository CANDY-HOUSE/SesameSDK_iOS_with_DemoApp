//
//  VC+Extension.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

extension UIViewController {
    class func getCurrentVC() -> UIViewController?{
        var result:UIViewController?
        var window = UIApplication.shared.keyWindow
        if window?.windowLevel != UIWindow.Level.normal{
            let windows = UIApplication.shared.windows
            for tmpWin in windows{
                if tmpWin.windowLevel == UIWindow.Level.normal{
                    window = tmpWin
                    break
                }
            }
        }
        let fromView = window?.subviews[0]
        if let nextRespnder = fromView?.next{
            if nextRespnder.isKind(of: UIViewController.self){
                result = nextRespnder as? UIViewController
            }else{
                result = window?.rootViewController
            }
        }
        return result
    }
}

extension UIAlertAction {
    class func addAction(title:String,style:UIAlertAction.Style,handler:((UIAlertAction) -> Void)?) -> UIAlertAction{
        let alertAction = UIAlertAction(title: title, style: style, handler: handler);
        return alertAction
    }
}

extension UIAlertController {

    class func  showAlertController(_ sender:UIView,title:String? = nil,msg:String? = nil,style:UIAlertController.Style, actions:[UIAlertAction]) {

        let close = UIAlertAction.addAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                            style: .cancel) { (action) in

           }
        let VC = UIViewController.getCurrentVC()
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: style);
        for action in actions{
            alertController.addAction(action)
        }
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        VC?.present(alertController, animated: true, completion: nil);
    }
}

extension UIViewController {
    func showDFUAlertFrom(sender: UIView,
                          dfuProcess: @escaping (DFUIndicator) -> Void,
                          abortHandler: @escaping ()->Void) {
        let chooseDFUModeAlertController = UIAlertController(title: "",
                                                             message: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                             preferredStyle: .actionSheet)
        let actionSheetApplicationDFU = UIAlertAction(title: CHDFUHelper.applicationDfuFileName() ?? "",
                                                      style: .default) { [weak self] _ in
                                                        self?.showApplicaitonDFUAlertFrom(sender: sender,
                                                                                          dfuProcess: dfuProcess,
                                                                                          abortHandler: abortHandler)
        }
                
        //        let actionSheetBootloaderDFU = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.bootloader".localized, style: .default) { _ in
        //            self.showBootloaderDFUAlertForIndexPath()
        //        }
                
        chooseDFUModeAlertController.addAction(actionSheetApplicationDFU)
        //        chooseDFUModeAlertController.addAction(actionSheetBootloaderDFU)
        chooseDFUModeAlertController.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
                                                             style: .cancel,
                                                             handler: nil))
        if let popover = chooseDFUModeAlertController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(chooseDFUModeAlertController, animated: true, completion: nil)
    }
    
    func showApplicaitonDFUAlertFrom(sender: UIView,
                                     dfuProcess: @escaping (DFUIndicator) -> Void,
                                     abortHandler: @escaping ()->Void) {
        let dfu = UIAlertAction
            .addAction(title: "co.candyhouse.sesame-sdk-test-app.Start".localized,
                       style: .destructive) { [unowned self] (action) in
                        UIApplication.shared.isIdleTimerDisabled = true
                        let progressIndicator = DFUIndicator.shared
                        progressIndicator.presentingViewController = self
                        progressIndicator.callBack = { _ in
                            UIApplication.shared.isIdleTimerDisabled = false
                        }
                        progressIndicator.dfuInitializedWithAbortHandler {
                            UIApplication.shared.isIdleTimerDisabled = false
                            abortHandler()
                        }
                        dfuProcess(progressIndicator)
//                            self.viewModel.dfuApplicationDeviceWithObserver(progressIndicator)
            }
            let alertController = UIAlertController(title: "",
                                                    message: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                    preferredStyle: .alert)
            let cancel = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized, style: .cancel, handler: nil)
            alertController.addAction(dfu)
            alertController.addAction(cancel)
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(alertController, animated: true, completion: nil)
    }
    
    
    //    func showBootloaderDFUAlertForIndexPath() {
    //        let dfu = UIAlertAction
    //            .addAction(title: viewModel.dfuActionText(),
    //                       style: .destructive) { (action) in
    //                        let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
    //
    //                        }
    //                        progressIndicator.dfuInitialized {
    //                            self.viewModel.cancelDFU()
    //                        }
    //                        self.viewModel.dfuBootloaderDeviceWithObserver(progressIndicator)
    //        }
    //        let alertController = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.bootloader_dfu".localized,
    //                                                message: viewModel.bootloaderDfuFileName(),
    //                                                preferredStyle: .alert)
    //        let cancel = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized, style: .cancel, handler: nil)
    //        alertController.addAction(dfu)
    //        alertController.addAction(cancel)
    //        present(alertController, animated: true, completion: nil)
    //    }
}
