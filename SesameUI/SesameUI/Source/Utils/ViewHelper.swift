//
//  ViewHelper.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/09/02.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

let loadingViewTag = 999 //?? remove logic bomb
let errorViewTag = 998

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
    /**
    *  进度条显示
    * view：附着的view界面
    * backgroudeColor：背景色默认为透明色，此时显示原有界面内容
    * floating ： 是否居中 悬浮
     */
    static func showLoadingInView(view: UIView?, backgroudeColor: UIColor = .clear, floating: Bool = false) {
        if(view == nil){
            return
        }
        if view!.viewWithTag(loadingViewTag) != nil && view!.frame.size.width < 20 {
            return
        }
        let loadingView: UIView
        
        if floating {
            loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            loadingView.center = view!.center
            loadingView.layer.cornerRadius = 8
            loadingView.clipsToBounds = true
        } else {
            loadingView = UIView(frame: view!.bounds)
        }
        
        loadingView.tag = loadingViewTag
        loadingView.backgroundColor = backgroudeColor
        
        // 使用大尺寸的指示器
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .gray)
        }
        
        if(floating) {
            indicator.transform = CGAffineTransform(scaleX: 1.2, y: 1.5)
        }
        
        indicator.color = .gray
        
        // 将指示器放在loadingView的中心
        indicator.center = CGPoint(x: loadingView.bounds.width/2,
                                 y: loadingView.bounds.height/2)
        
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        view!.addSubview(loadingView)
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
    
    static func showErrorView(view: UIView?,
                             image: UIImage?,
                             message: String,
                             onClick: (() -> Void)?) {
        if view == nil {
            return
        }
        
        // 移除已存在的错误视图
        if let existingView = view!.viewWithTag(errorViewTag) {
            existingView.removeFromSuperview()
        }
        // 创建全屏错误视图
        let errorView = UIView(frame: view!.bounds)
        errorView.tag = errorViewTag
        errorView.backgroundColor = .white
        
        // 创建垂直堆叠视图
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建图片视图
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = CGSize(width: 120, height: 120)
        
        // 创建标签
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 16)
        
        // 将视图添加到堆叠视图
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        // 将堆叠视图添加到错误视图
        errorView.addSubview(stackView)
        
        // 设置堆叠视图约束
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: errorView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: errorView.trailingAnchor, constant: -20)
        ])
        
        // 添加点击手势
        if let callback = onClick {
            errorView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: nil, action: nil)
            tapGesture.addTarget { _ in
                callback()
            }
            errorView.addGestureRecognizer(tapGesture)
        }
        
        view!.addSubview(errorView)
    }
    
    static func hideErrorView(view: UIView?) {
        DispatchQueue.main.async {
            view?.viewWithTag(errorViewTag)?.removeFromSuperview()
        }
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
//        let offsetPoint = CGPoint.init(x: 0, y: frame.size.height)
//        tableView.setContentOffset(offsetPoint, animated: true)
    }
}

extension UITapGestureRecognizer {
    func addTarget(action: @escaping (UITapGestureRecognizer) -> Void) {
        let sleeve = ClosureSleeve(action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke(_:)))
        objc_setAssociatedObject(self, "gesture", sleeve, .OBJC_ASSOCIATION_RETAIN)
    }
}

private class ClosureSleeve {
    let closure: (UITapGestureRecognizer) -> Void

    init(_ closure: @escaping (UITapGestureRecognizer) -> Void) {
        self.closure = closure
    }

    @objc func invoke(_ sender: UITapGestureRecognizer) {
        closure(sender)
    }
}

