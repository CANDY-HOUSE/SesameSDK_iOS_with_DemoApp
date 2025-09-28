//
//  Untitled.swift
//  SesameUI
//
//  Created by eddy on 2025/9/17.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import UIKit
import WebKit

typealias CHWebViewSchemeHandler = (CHWebView, URL, [String: String]) -> Void

class CHWebView: UIView {
    // MARK: - Configuration
    struct Configuration {
        let scene: String?
        let extInfo: [String: String]?
        let directURL: String?
        
        init(scene: String, extInfo: [String: String]? = nil) {
            self.scene = scene
            self.extInfo = extInfo
            self.directURL = nil
        }
        
        init(directURL: String) {
            self.scene = nil
            self.extInfo = nil
            self.directURL = directURL
        }
    }
    
    // MARK: - Properties
    private var configuration: Configuration!
    weak var webView: WKWebView!
    private var schemeHandlers: [String: CHWebViewSchemeHandler] = [:]
    
    // MARK: - Callbacks
    var didCreated: ((CHWebView) -> Void)?
    var loadError: ((Error) -> Void)?
    var loadSuccess: (() -> Void)?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    convenience init(configuration: Configuration) {
        self.init(frame: .zero)
        self.configuration = configuration
        loadWebView()
    }
    
    deinit {
        cleanupWebView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .white
    }
    
    // MARK: - Public Methods
    func registerSchemeHandler(_ scheme: String, handler: @escaping CHWebViewSchemeHandler) {
        schemeHandlers[scheme] = handler
    }
    
    func unregisterSchemeHandler(_ scheme: String) {
        schemeHandlers.removeValue(forKey: scheme)
    }
    
    func refresh() {
        cleanupWebView()
        loadWebView()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    // MARK: - WebView Loading
    private func loadWebView() {
        guard let configuration = configuration else { return }
        if let directURL = configuration.directURL {
            setupWebView(urlString: directURL)
        } else if let scene = configuration.scene {
            CHUserAPIManager.shared.getWebUrlByScene(scene: scene, extInfo: configuration.extInfo ?? [:]) { [weak self] result in
                executeOnMainThread {
                    guard let self = self else { return }
                    self.hideLoading()
                    switch result {
                    case .success(let response):
                        self.setupWebView(urlString: response.data)
                    case .failure(let error):
                        self.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }
    
    // MARK: - Loading States
    private func showLoading() {
        ViewHelper.showLoadingInView(view: self)
    }
    
    private func hideLoading() {
        ViewHelper.hideLoadingView(view: self)
    }
    
    // MARK: - Cleanup
    private func cleanupWebView() {
        guard let webView = webView else { return }
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        
        let dataStore = webView.configuration.websiteDataStore
        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                           modifiedSince: Date(timeIntervalSince1970: 0)) { }
        
        webView.removeFromSuperview()
    }
}

// MARK: - WebView Setup
extension CHWebView {
    private func setupWebView(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView?.removeFromSuperview()
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        if #available(iOS 17.4, *) {
            webView.scrollView.bouncesVertically = false
        }
#if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
#endif
        webView.allowsBackForwardNavigationGestures = true
        addSubview(webView)
        webView.autoPinEdgesToSuperview(safeArea: false)
        let request = URLRequest(url: url)
        webView.load(request)
        didCreated?(self)
    }
}

// MARK: - WKNavigationDelegate
extension CHWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoading()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoading()
        loadSuccess?()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoading()
        loadError?(error)
        makeToast(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        hideLoading()
        loadError?(error)
        makeToast(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let urlString = url.absoluteString
        for (scheme, handler) in schemeHandlers {
            if urlString.hasPrefix(scheme) {
                var params: [String: String] = [:]
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    for item in queryItems {
                        params[item.name] = item.value ?? ""
                    }
                }
                handler(self, url, params)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - Factory Methods
extension CHWebView {
    static func instanceWithScene(_ scene: String,
                               extInfo: [String: String]? = nil) -> CHWebView {
        let config = Configuration(scene: scene, extInfo: extInfo)
        return CHWebView(configuration: config)
    }
    
    static func instanceWithURL(_ url: String) -> CHWebView {
        let config = Configuration(directURL: url)
        return CHWebView(configuration: config)
    }
}
