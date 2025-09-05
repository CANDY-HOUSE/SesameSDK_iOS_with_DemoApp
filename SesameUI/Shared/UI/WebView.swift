//
//  WebView.swift
//  SesameUI
//
//  Created by frey Mac on 2025/7/22.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SwiftUI
import WebKit
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var currentURL: URL?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("WebView failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("WebView provisional failed: \(error.localizedDescription)")
        }
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        if #available(iOS 17.4, *) {
            webView.scrollView.bouncesVertically = false
        }
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
}
