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
    private var sceneInfo: (scene: String, extInfo: [String: String]?)!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
    }
    
    private func setupWebView() {
        var webView: CHWebView!
        if urlStr != nil {
            webView = CHWebView.instanceWithURL(urlStr)
        } else {
            webView = CHWebView.instanceWithScene(sceneInfo.scene, extInfo: sceneInfo.extInfo)
        }
        view.addSubview(webView)
        webView.autoPinEdgesToSuperview()
        registerSchemeHandlers(webView: webView)
        registerMessageHandlers(webView: webView)
    }
}

extension CHWebViewController {
    static func instanceWithURL(_ url: String) -> CHWebViewController {
        let vc = CHWebViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.urlStr = url
        return vc
    }
    static func instanceWithScene(_ scene: String,
                               extInfo: [String: String]? = nil) -> CHWebViewController {
        let vc = CHWebViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.sceneInfo = (scene, extInfo)
        return vc
    }
}
