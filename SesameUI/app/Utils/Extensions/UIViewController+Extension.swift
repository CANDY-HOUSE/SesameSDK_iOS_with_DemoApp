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
