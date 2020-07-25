//
//  ViewHelper.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/09/02.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

let loadingViewTag = 999//?? remove logic bomb

class ViewHelper: NSObject {
    class func showLoadingInView(view: UIView?) {
        if(view == nil){
            return
        }
        if view!.viewWithTag(loadingViewTag) != nil && view!.frame.size.width < 20 {
            return
        }

        DispatchQueue.main.async {
            let loadingView = UIView(frame: view!.bounds)
            loadingView.tag = loadingViewTag
            let indicator = UIActivityIndicatorView(style: .gray)
            indicator.center = loadingView.center
            indicator.startAnimating()
            loadingView.addSubview(indicator)
            view!.addSubview(loadingView)
        }
    }

    class func hideLoadingView(view: UIView?) {
        DispatchQueue.main.async {
            let loadingView = view?.viewWithTag(loadingViewTag)
            if loadingView != nil {
                loadingView!.removeFromSuperview()
            }
        }
    }

    class func alert(_ title: String, _ message: String, _ viewController: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.OK".localized,
                                          style: .default,
                                          handler: nil))
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    class func showAlertMessage(title: String, message: String, actionTitle: String, viewController: UIViewController) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
            viewController.present(alert, animated: true, completion: nil)
        })
    }
}
