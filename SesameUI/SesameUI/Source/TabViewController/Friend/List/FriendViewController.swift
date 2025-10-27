//
//  FriendListViewController.swift
//  SesameUI
//
//  Created by tse on 2023/05/27.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF

extension FriendViewController {
    static func instance() -> FriendViewController {
        let vc = FriendViewController(nibName: nil, bundle: nil)
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
    static func instanceWithFriendAdd() -> FriendViewController {
        let vc = FriendViewController(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.addFriend = true
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class FriendViewController: CHBaseViewController {
    private var userState: UserState = .unknown
    private weak var webView: CHWebView!
    private var addFriend: Bool = false
    
    deinit {
        webView?.cleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        if !addFriend {
            setNavigationItemRightMenu()
            monitorAWSMobileClientUserState()
        }
    }
    
    func monitorAWSMobileClientUserState() {
        let statusChangeHandler: (_ state: AWSMobileClientXCF.UserState) -> Void = { [weak self] state in
            if (state == .signedIn && self?.userState == .signedOut) ||
               (state == .signedOut && self?.userState == .signedIn) {
                self?.webView.refresh()
            }
            self?.userState = state
        }
        AWSMobileClient.default().addUserStateListener(self) { state, dic in
            executeOnMainThread {
                statusChangeHandler(state)
            }
        }
        userState = AWSMobileClient.default().currentUserState
    }
    
    private func setupWebView() {
        let webView = CHWebView.instanceWithScene(addFriend ? "contact-add": "contacts")
        webView.registerSchemeHandler("ssm://UI/webview/open") { [weak self] view, url, param in
            guard let self = self else {
                return
            }
            guard let urlStr = param["url"] else {
                return
            }
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveFriendNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated:true)
        }
        self.webView = webView
        view.addSubview(webView)
        webView.autoPinEdgesToSuperview()
        webView.loadRequest()
        webView.didCreated = { web in
            web.enablePullToRefresh {
                self.reloadFriends()
            }
        }
        webView.registerSchemeHandler(WebViewSchemeType.registNotify.rawValue) { [unowned self] _, _, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveFriendNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
        }
        webView.registerSchemeHandler(WebViewSchemeType.notify.rawValue) { view, url, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notifyName), object: nil, userInfo: param)
            }
        }
    }
    
    @objc private func onReceiveFriendNotification(notify: Notification) {
        guard let notifyName = notify.userInfo?["notifyName"] as? String else {
            return
        }
        if notifyName == "FriendChanged" {
            reloadFriends()
            navigationController?.popToRootViewController(animated: true)
        } else if (notifyName == "RefreshList") {
            reloadFriends()
        }
    }
    
    func reloadFriends() {
        webView?.reload()
    }
}
