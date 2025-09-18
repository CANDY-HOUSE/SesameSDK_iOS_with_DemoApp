//
//  CHBaseViewController+DeviceMember.swift
//  SesameUI
//
//  Created by eddy on 2025/9/18.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import UIKit

extension CHBaseViewController {
    private struct WebAssociatedKeys {
        static var deviceWebViewKey: UInt8 = 0
    }
    private var deviceWebView: CHWebView? {
        get {
            return objc_getAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey) as? CHWebView
        }
        set {
            objc_setAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func deviceMemberView(_ deviceUUID: String) -> UIView {
        let collectionViewContainer = UIView(frame: .zero)
        collectionViewContainer.autoLayoutHeight(80)
        let web = CHWebView.instanceWithScene("device-user", extInfo: ["deviceUUID": deviceUUID])
        self.deviceWebView = web
        web.registerSchemeHandler("ssm://UI/webview/open") { [weak self] view, url, param in
            guard let self = self else {
                return
            }
            guard let urlStr = param["url"] else {
                return
            }
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated:true)
        }
        collectionViewContainer.addSubview(web)
        web.autoPinEdgesToSuperview(safeArea: false)
        return collectionViewContainer;
    }
    
    @objc private func onReceiveNotification(notify: Notification) {
        if let notifyName = notify.userInfo?["notifyName"] as? String, notifyName == "DeviceMemberChanged" {
            reloadMembers()
        }
    }
    
    func reloadMembers() {
        deviceWebView?.reload()
    }
}
