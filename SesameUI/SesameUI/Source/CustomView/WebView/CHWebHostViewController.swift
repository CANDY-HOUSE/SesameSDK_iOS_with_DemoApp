//
//  CHWebHostViewController.swift
//  SesameUI
//
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

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

class CHWebHostViewController: CHBaseViewController, PullToRefreshable, WebNotificationObserving, UIGestureRecognizerDelegate {

    // MARK: - 页面能力配置

    /// 承载页的能力开关。tab 页由子类覆写各项；子页由工厂显式注入。
    struct Options {
        /// 是否显示右上角菜单
        var showsNavigationRightMenu: Bool
        /// 是否默认启用下拉刷新（否则由 H5 的 requestEnablePullRefresh 按需开启）
        var enablesPullToRefresh: Bool
        /// 是否使用支持网页内后退的自定义返回按钮
        var usesWebViewBackButton: Bool

        /// tab 页：显示右上菜单、支持下拉刷新
        static let tabHost = Options(
            showsNavigationRightMenu: true,
            enablesPullToRefresh: true,
            usesWebViewBackButton: false
        )

        /// push 出来的子页：网页内返回，无菜单／无默认下拉刷新
        static func subPage() -> Options {
            Options(
                showsNavigationRightMenu: false,
                enablesPullToRefresh: false,
                usesWebViewBackButton: true
            )
        }
    }

    // MARK: - 子类配置点（覆写）／工厂注入
    /// 数据源：scene（与 webDirectURL 二选一）
    var webScene: String? { injectedScene }
    /// 数据源：直接 URL（优先于 scene）
    var webDirectURL: String? { injectedURL }
    /// scene 附加参数
    var webExtInfo: [String: String]? { injectedExtInfo }
    /// 是否显示右上角菜单
    var showsNavigationRightMenu: Bool { options.showsNavigationRightMenu }
    /// 是否启用下拉刷新
    var enablesPullToRefresh: Bool { options.enablesPullToRefresh }
    /// 是否使用支持网页后退的自定义返回按钮
    var usesWebViewBackButton: Bool { options.usesWebViewBackButton }
    /// 收到此通知名时：reload 并 popToRoot（WebNotificationObserving）
    var reloadAndPopNotifyName: String? { nil }

    // MARK: - 工厂注入
    private var injectedURL: String?
    private var injectedScene: String?
    private var injectedExtInfo: [String: String]?
    /// 默认按 tab 页；工厂创建子页时注入 .subPage()
    private var options: Options = .tabHost
    /// 工厂注入的额外 handler 注册（通用扩展点，基类不关心具体业务）
    private var injectedHandlerRegistration: HandlerRegistration?

    // MARK: - 通用扩展点
    /// 额外 handler 的注册闭包：接收承载页与其 webView，由能力模块自行注册
    typealias HandlerRegistration = (CHWebHostViewController, CHWebView) -> Void
    /// 页面销毁前的清理闭包：以参数接收承载页（不捕获 self，故 deinit 中安全调用）
    private var destroyPageHandlers: [(CHWebHostViewController) -> Void] = []
    /// 供能力模块登记销毁清理（基类不关心清理内容）
    func addDestroyPageHandler(_ handler: @escaping (CHWebHostViewController) -> Void) {
        destroyPageHandlers.append(handler)
    }

    // MARK: - webView

    private(set) weak var webView: CHWebView!

    deinit {
        NotificationCenter.default.removeObserver(self)
        destroyPageHandlers.forEach { $0(self) }
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
        if usesWebViewBackButton {
            setupWebViewBackButton()
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
        web.registerMessageHandlers()
        registerExtraHandlers(on: web)
        injectedHandlerRegistration?(self, web)

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
            self.navigationController?.pushViewController(CHWebHostViewController.instanceWithURL(urlStr), animated: true)
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

    // MARK: - 子页返回按钮（支持网页内后退）
    private func setupWebViewBackButton() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackAction)
        )
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @objc private func handleBackAction() {
        if webView?.webView?.canGoBack == true {
            webView?.goBack()
        } else {
            navigationController?.popViewController(animated: true)
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

// MARK: - UINavigationBarDelegate（子页：优先网页后退）
extension CHWebHostViewController: UINavigationBarDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        guard usesWebViewBackButton else { return true }
        if webView?.webView?.canGoBack == true {
            webView?.goBack()
            return false
        }
        return true
    }
}

// MARK: - 子页工厂
extension CHWebHostViewController {
    static func instanceWithURL(_ url: String,
                                options: Options = .subPage(),
                                registerHandlers: HandlerRegistration? = nil) -> CHWebHostViewController {
        let vc = CHWebHostViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.options = options
        vc.injectedHandlerRegistration = registerHandlers
        vc.injectedURL = url
        return vc
    }

    static func instanceWithScene(_ scene: String,
                                  extInfo: [String: String]? = nil,
                                  options: Options = .subPage(),
                                  registerHandlers: HandlerRegistration? = nil) -> CHWebHostViewController {
        let vc = CHWebHostViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.options = options
        vc.injectedHandlerRegistration = registerHandlers
        vc.injectedScene = scene
        vc.injectedExtInfo = extInfo
        return vc
    }
}
