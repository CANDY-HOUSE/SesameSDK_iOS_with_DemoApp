//
//  ViewHelper.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/09/02.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

let loadingViewTag = 999 

final class ViewHelper: NSObject {
    private static var loadingViewController: UIViewController?
    static func showLoadingIndicatorOnTopVC() {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            hideLoadingIndicatorFromTopVC()
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            loadingViewController = topController
            showLoadingInView(view: loadingViewController?.view)
        }
    }
    
    static func hideLoadingIndicatorFromTopVC() {
        hideLoadingView(view: loadingViewController?.view)
    }
    
    static func showLoadingInView(view: UIView?) {
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

    static func hideLoadingView(view: UIView?) {
        DispatchQueue.main.async {
            let loadingView = view?.viewWithTag(loadingViewTag)
            if loadingView != nil {
                loadingView!.removeFromSuperview()
            }
        }
    }

    static func alert(_ title: String, _ message: String, _ viewController: UIViewController, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "co.candyhouse.sesame2.OK".localized,
                                          style: .default,
                                          handler: handler))
            alert.popoverPresentationController?.sourceView = viewController.view
            alert.popoverPresentationController?.sourceRect = .init(x: viewController.view.center.x,
                                                                    y: viewController.view.center.y,
                                                                    width: 0,
                                                                    height: 0)
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    static func showAlertMessage(title: String, message: String, actionTitle: String, viewController: UIViewController, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
            alert.popoverPresentationController?.sourceView = viewController.view
            alert.popoverPresentationController?.sourceRect = .init(x: viewController.view.center.x,
                                                                    y: viewController.view.center.y,
                                                                    width: 0,
                                                                    height: 0)
            viewController.present(alert, animated: true, completion: nil)
        })
    }
}

extension UIRefreshControl {
    func programaticallyBeginRefreshing(in tableView: UITableView) {
        beginRefreshing()
        let offsetPoint = CGPoint.init(x: 0, y: -frame.size.height)
        tableView.setContentOffset(offsetPoint, animated: true)
    }
    func programaticallyEndRefreshing(in tableView: UITableView) {
        endRefreshing()
    }
}
