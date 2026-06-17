//
//  VisionViewController.swift
//  SesameUI
//
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit

extension VisionViewController {
    static func instance() -> VisionViewController {
        let vc = VisionViewController(nibName: nil, bundle: nil)
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class VisionViewController: CHBaseViewController {
    private weak var webView: CHWebView!

    deinit {
        webView?.cleanup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        setNavigationItemRightMenu()
    }

    private func setupWebView() {
        let webView = CHWebView.instanceWithScene("vision")
        webView.registerSchemeHandler("ssm://UI/webview/open") { [weak self] _, _, param in
            guard let self = self, let urlStr = param["url"] else {
                return
            }
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveVisionNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated: true)
        }
        self.webView = webView
        view.addSubview(webView)
        webView.autoPinEdgesToSuperview()
        webView.loadRequest()
        webView.didCreated = { [weak self] web in
            web.enablePullToRefresh { [weak self] in
                self?.reloadVision()
            }
        }
        webView.registerSchemeHandler(WebViewSchemeType.registNotify.rawValue) { [unowned self] _, _, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveVisionNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
        }
        webView.registerSchemeHandler(WebViewSchemeType.notify.rawValue) { view, url, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notifyName), object: nil, userInfo: param)
            }
        }
    }

    @objc private func onReceiveVisionNotification(notify: Notification) {
        guard let notifyName = notify.userInfo?["notifyName"] as? String else {
            return
        }
        if notifyName == "VisionChanged" {
            reloadVision()
            navigationController?.popToRootViewController(animated: true)
        } else if notifyName == "RefreshList" {
            reloadVision()
        }
    }

    func reloadVision() {
        webView?.reload()
    }
}
