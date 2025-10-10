//
//  CHBaseViewController+DeviceMember.swift
//  SesameUI
//
//  Created by eddy on 2025/9/18.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import UIKit

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
    
    func deviceMemberWebView(_ deviceUUID: String) -> UIView {
        let collectionViewContainer = UIView(frame: .zero)
        collectionViewContainer.autoLayoutHeight(80)
        let web = CHWebView.instanceWithScene("device-user", extInfo: ["deviceUUID": deviceUUID])
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
        collectionViewContainer.addSubview(web)
        web.autoPinEdgesToSuperview(safeArea: false)
        web.loadRequest()
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
            presentFindFriendsViewController { [weak self] newVal in
                guard let self = self else { return }
                ViewHelper.showLoadingInView(view: self.view)
                FindFriendHandler.shared.addFriendByEmail(newVal.trimmingCharacters(in: .whitespacesAndNewlines)) { [weak self] (friend, err) in
                    guard let self = self else { return }
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        if let error = err {
                            self.view.makeToast(error.errorDescription())
                        } else {
                            // 進入詳情
                            if let navController = GeneralTabViewController.getTabViewControllersBy(1) as? UINavigationController, let listViewController = navController.viewControllers.first as? FriendListViewController {
                                if listViewController.isViewLoaded {
                                    listViewController.reloadFriends()
                                }
                            }
                            self.navigationController?.pushViewController(CHWebViewController.instanceWithScene("contact-info", extInfo: ["email": friend!.email, "subUUID": friend!.subId.uuidString.lowercased()]), animated: true)
                        }
                    }
                }
            }
        default:break;
        }
    }
}
