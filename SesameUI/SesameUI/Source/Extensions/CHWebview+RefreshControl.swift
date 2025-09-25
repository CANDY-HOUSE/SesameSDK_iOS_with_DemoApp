//
//  CHWebview.swift
//  SesameUI
//
//  Created by eddy on 2025/9/25.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import UIKit

private struct AssociatedKeys {
    static var refreshHandler: UInt8 = 0
    static var refreshControl: UInt8 = 1
}

extension CHWebView {
    func enablePullToRefresh(refreshHandler: @escaping () -> Void) {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        objc_setAssociatedObject(self, &AssociatedKeys.refreshHandler, refreshHandler, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.refreshControl, refreshControl, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        webView.scrollView.refreshControl = refreshControl
        webView.scrollView.bounces = true
    }
    
    func endRefreshing() {
        if let refreshControl = objc_getAssociatedObject(self, &AssociatedKeys.refreshControl) as? UIRefreshControl {
            refreshControl.endRefreshing()
        }
    }
    
    @objc private func handleRefresh() {
        if let refreshHandler = objc_getAssociatedObject(self, &AssociatedKeys.refreshHandler) as? () -> Void {
            refreshHandler()
            endRefreshing()
        }
    }
}

