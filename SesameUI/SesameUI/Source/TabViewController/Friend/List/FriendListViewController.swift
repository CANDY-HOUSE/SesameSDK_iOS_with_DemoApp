//
//  FriendListViewController.swift
//  SesameUI
//
//  Created by tse on 2023/05/27.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF

extension FriendListViewController {
    static func instance() -> FriendListViewController {
        let vc = FriendListViewController(nibName: nil, bundle: nil)
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class FriendListViewController: CHBaseViewController {
    private var userState: UserState = .unknown
    private weak var webView: CHWebView!
    
    deinit {
        webView?.cleanup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationItemRightMenu()
        view.backgroundColor = .white
        setupWebView()
        monitorAWSMobileClientUserState()
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
        let webView = CHWebView.instanceWithScene("contacts")
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
    }
    
    @objc private func onReceiveFriendNotification(notify: Notification) {
        if let notifyName = notify.userInfo?["notifyName"] as? String, notifyName == "FriendChanged" {
            reloadFriends()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func reloadFriends() {
        webView.reload()
    }
}
