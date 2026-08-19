//
//  WebHostingCapabilities.swift
//  SesameUI
//
//  Web 承载页的正交能力：下拉刷新、网页通知处理。
//  以 protocol + 默认实现表达「能力」，与 CHWebHostViewController 的「状态/生命周期」基座解耦。
//

import UIKit

// MARK: - 下拉刷新能力

protocol PullToRefreshable: AnyObject {
    /// 是否启用下拉刷新
    var enablesPullToRefresh: Bool { get }
    /// 刷新动作
    func reloadWeb()
}

extension PullToRefreshable {
    var enablesPullToRefresh: Bool { true }

    /// 为指定 webView 绑定下拉刷新（能力自包含，无 @objc 依赖）
    func bindPullToRefresh(to web: CHWebView) {
        guard enablesPullToRefresh else { return }
        web.enablePullToRefresh { [weak self] in
            self?.reloadWeb()
        }
    }
}

// MARK: - 网页通知处理能力

protocol WebNotificationObserving: AnyObject {
    /// 收到此通知名时：reload 并 popToRoot（如 "FriendChanged"）
    var reloadAndPopNotifyName: String? { get }
    /// 刷新动作
    func reloadWeb()
    /// popToRoot 动作（由具体 VC 提供导航实现）
    func popToRootForWebNotification()
}

extension WebNotificationObserving {
    var reloadAndPopNotifyName: String? { nil }

    /// 网页通知的处理决策（纯逻辑，可单测、可复用）。
    /// @objc selector 因 UIKit/ObjC 约束必须留在类里，仅做转发；决策集中在此。
    func handleWebNotification(_ notifyName: String) {
        if let popName = reloadAndPopNotifyName, notifyName == popName {
            reloadWeb()
            popToRootForWebNotification()
        } else if notifyName == "RefreshList" {
            reloadWeb()
        }
    }
}
