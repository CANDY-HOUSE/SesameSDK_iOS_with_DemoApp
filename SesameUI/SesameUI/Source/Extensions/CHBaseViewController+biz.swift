//
//  CHBaseViewController+DeviceMember.swift
//  SesameUI
//
//  Created by eddy on 2025/9/18.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import UIKit
import SesameSDK

// Device Owner Manage
extension CHBaseViewController {
    private struct WebAssociatedKeys {
        static var deviceWebViewKey: UInt8 = 0
    }
    var deviceMemberWebView: CHWebView? {
        get {
            return objc_getAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey) as? CHWebView
        }
        set {
            objc_setAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func deviceMemberWebView(_ device: CHDevice) -> UIView {
        let collectionViewContainer = UIView(frame: .zero)
        let heightConstraint = collectionViewContainer.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive = true
        let web = CHWebView.instanceWithScene("device-setting", extInfo: ["deviceUUID": device.deviceId.uuidString, "keyLevel": "\(device.keyLevel)"])
        self.deviceMemberWebView = web
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
        web.registerMessageHandler(WebViewMessageType.requestAutoLayoutHeight.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let height = requestData["height"] as? CGFloat {
                heightConstraint.constant = height
                UIView.performWithoutAnimation {
                    if let parentView = collectionViewContainer.superview {
                        parentView.layoutIfNeeded()
                    }
                }
            }
        }
        collectionViewContainer.addSubview(web)
        web.autoPinEdgesToSuperview(safeArea: false)
        web.loadRequest()
        web.registerMessageHandlers()
        return collectionViewContainer;
    }
    
    @objc private func onReceiveNotification(notify: Notification) {
        if let notifyName = notify.userInfo?["notifyName"] as? String, notifyName == "DeviceMemberChanged" {
            reloadMembers()
        }
    }
    
    func reloadMembers() {
        deviceMemberWebView?.reload()
    }
}

// HomePage Popup
extension CHBaseViewController {
    func setNavigationItemRightMenu() {
        let copyAction = UIAction(
            title: "co.candyhouse.sesame2.NewSesame".localized,
            image: UIImage.SVGImage(named: "cube", fillColor: .black),
            identifier: UIAction.Identifier("new-device")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        
        let shareAction = UIAction(
            title: "co.candyhouse.sesame2.scanQRCode".localized,
            image: UIImage.SVGImage(named: "qr-code-scan", fillColor: .black),
            identifier: UIAction.Identifier("scan-qrcode")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        
        let editAction = UIAction(
            title: "co.candyhouse.sesame2.AddContacts".localized,
            image: UIImage.SVGImage(named: "find_friend", fillColor: .black),
            identifier: UIAction.Identifier("add-friend")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        let mainMenu = UIMenu(
            title: "",
            children: [copyAction, shareAction, editAction]
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
            menu: mainMenu
        )
    }
    
    private func onMenuItemClick(_ action: UIAction) {
        switch action.identifier.rawValue {
        case "new-device":
            presentRegisterSesame2ViewController()
        case "scan-qrcode":
            presentScanViewController()
        case "add-friend":
            navigationController?.pushViewController(FriendViewController.instanceWithFriendAdd(), animated: true)
        default:break;
            
        }
    }
}
