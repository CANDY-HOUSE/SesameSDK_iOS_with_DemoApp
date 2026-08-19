//
//  CHWebHostViewController.swift
//  SesameUI
//
//  承载单个 CHWebView 的页面基类：统一 webView 生命周期、通用 scheme、下拉刷新、
//  网页通知（reload / reload+popToRoot）与右上菜单。子类只需声明数据源与差异配置。
//

import UIKit

class CHWebHostViewController: CHBaseViewController, PullToRefreshable, WebNotificationObserving {

    // MARK: - 子类配置点（覆写）

    /// 数据源：scene（与 webDirectURL 二选一）
    var webScene: String? { nil }
    /// 数据源：直接 URL（优先于 scene）
    var webDirectURL: String? { nil }
    /// scene 附加参数
    var webExtInfo: [String: String]? { nil }
    /// 是否显示右上角菜单
    var showsNavigationRightMenu: Bool { true }
    /// 是否启用下拉刷新（PullToRefreshable）
    var enablesPullToRefresh: Bool { true }
    /// 收到此通知名时：reload 并 popToRoot（WebNotificationObserving）
    var reloadAndPopNotifyName: String? { nil }

    // MARK: - webView

    private(set) weak var webView: CHWebView!

    deinit {
        webView?.cleanup()
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        if showsNavigationRightMenu {
            setNavigationItemRightMenu()
        }
        didFinishInitialSetup()
    }

    /// 子类可覆写：完成基础初始化后的额外逻辑（如监听登录态）
    func didFinishInitialSetup() {}

    /// 子类可覆写：注册页面专属的额外 handler（如登录 bridge）
    func registerExtraHandlers(on web: CHWebView) {}

    // MARK: - Setup

    private func setupWebView() {
        let web: CHWebView
        if let url = webDirectURL {
            web = CHWebView.instanceWithURL(url)
        } else {
            web = CHWebView.instanceWithScene(webScene ?? "", extInfo: webExtInfo)
        }
        self.webView = web
        view.addSubview(web)
        web.autoPinEdgesToSuperview()

        registerCommonSchemeHandlers(on: web)
        registerExtraHandlers(on: web)

        web.didCreated = { [weak self] createdWeb in
            self?.bindPullToRefresh(to: createdWeb)
        }
        web.loadRequest()
    }

    private func registerCommonSchemeHandlers(on web: CHWebView) {
        // 打开子网页
        web.registerSchemeHandler("ssm://UI/webview/open") { [weak self] _, _, param in
            guard let self = self, let urlStr = param["url"] else { return }
            if let notifyName = param["notifyName"] {
                self.observeWebNotification(named: notifyName)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated: true)
        }
        // 注册网页通知监听
        web.registerSchemeHandler(WebViewSchemeType.registNotify.rawValue) { [weak self] _, _, param in
            if let notifyName = param["notifyName"] {
                self?.observeWebNotification(named: notifyName)
            }
        }
        // 广播网页通知
        web.registerSchemeHandler(WebViewSchemeType.notify.rawValue) { _, _, param in
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.post(name: Notification.Name(notifyName), object: nil, userInfo: param)
            }
        }
    }

    // MARK: - Web notification

    private func observeWebNotification(named name: String) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWebNotification(_:)),
            name: Notification.Name(name),
            object: nil
        )
    }

    /// @objc selector 因 UIKit/ObjC 约束必须留在类里，仅转发给能力的决策逻辑
    @objc private func onWebNotification(_ notify: Notification) {
        guard let notifyName = notify.userInfo?["notifyName"] as? String else { return }
        handleWebNotification(notifyName)
    }

    /// WebNotificationObserving：提供导航实现
    func popToRootForWebNotification() {
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Public

    func reloadWeb() {
        webView?.reload()
    }
}
