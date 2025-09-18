//
//  CHWebViewController.swift
//  SesameUI
//
//  Created by eddy on 2025/9/17.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation

class CHWebViewController: CHBaseViewController {
    private var urlStr: String!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
    }
    
    private func setupWebView() {
        let webView = CHWebView.instanceWithURL(urlStr)
        view.addSubview(webView)
        webView.autoPinEdgesToSuperview()
        webView.registerSchemeHandler("ssm://UI/webview/notify") { view, url, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notifyName), object: nil, userInfo: param)
            }
        }
    }
}

extension CHWebViewController {
    static func instanceWithURL(_ url: String) -> CHWebViewController {
        let vc = CHWebViewController()
        vc.urlStr = url
        return vc
    }
}
