//
//  MeViewController.swift
//  SesameUI
//  [joi] [logout] 觀察
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF

extension UIApplication {
    var statusBarHeight: CGFloat {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .statusBarManager?.statusBarFrame.height ?? 0
    }
}

extension MeViewController {
    static func instance() -> MeViewController {
        let meViewController = MeViewController(nibName: nil, bundle: nil)
        let _ = UINavigationController(rootViewController: meViewController)
        return meViewController
    }
}

class MeViewController: CHBaseViewController {
    private weak var webView: CHWebView!
    var userState: UserState = .unknown
    lazy var userStateView = {
        let userStateView = UILabel(frame: .zero)
        userStateView.textAlignment = .center
        userStateView.translatesAutoresizingMaskIntoConstraints = false
        userStateView.font = UIFont(name: "TrebuchetMS", size: 15)
        userStateView.textColor = UIColor.placeHolderColor
        return userStateView
    }()
    lazy var scrollView = {
        let scroll = UIScrollView(frame: .zero)
        let refreshControl: UIRefreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshMe), for: .valueChanged)
        scroll.refreshControl = refreshControl
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()
    lazy var contentStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.distribution = .fill
        return stack
    }()
    lazy var versionLabel = {
        let lab = VersionLabel(downloadURL: "https://testflight.apple.com/join/Rok4GOFD")
        return lab
    }()
    var logOutView: CHUICallToActionView?
    var delAccountView: CHUICallToActionView?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationItemRightMenu()
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        arrangeSubview()
        AWSMobileClient.default().addUserStateListener(self) { state, _ in
            executeOnMainThread { [self] in
                userState = state
                userStateView.text = userState.rawValue
                logOutView?.isHidden = userState != .signedIn
                delAccountView?.isHidden = userState != .signedIn
            }
        }
        userState = AWSMobileClient.default().currentUserState
        userStateView.text = userState.rawValue
        logOutView?.isHidden = userState != .signedIn
        delAccountView?.isHidden = userState != .signedIn
    }
    
    @objc func refreshMe() {
        scrollView.refreshControl?.endRefreshing()
        webView?.reload()
    }

    func arrangeSubview() {
        // MARK: Web content
        contentStackView.addArrangedSubview(setupWebView())
        // MARK: - User state
        contentStackView.addArrangedSubview(userStateView)
        userStateView.autoLayoutHeight(30)
        userStateView.text = AWSMobileClient.default().currentUserState.rawValue
        userStateView.sizeToFit()
        // MARK: - Version Tag
        contentStackView.addArrangedSubview(versionLabel)
        versionLabel.autoLayoutHeight(30)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group,separatorViewBackgroundColor: .white))
        // MARK: - 登出
        let logoutTitle = "co.candyhouse.sesame2.LogOut".localized
        logOutView = CHUICallToActionView { [unowned self] sender,_ in
            guard let button = sender as? UIButton else {
                L.d("Error: logOutView sender is not a UIButton")
                return
            }
            self.performLogout(logOutTitle: logoutTitle, sender: button)
        }
        logOutView!.title = logoutTitle
        logOutView?.backgroundColor = .sesame2Gray
        contentStackView.addArrangedSubview(logOutView!)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick,separatorViewBackgroundColor: .white))
         //與刪除按鈕的距離
        let spacerView = UIView()
        contentStackView.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        // MARK: - 刪除帳號
        let delTitle = "co.candyhouse.sesame2.AccountDeletion".localized
        delAccountView = CHUICallToActionView { [unowned self] sender,_ in
            guard let button = sender as? UIButton else {
                L.d("Error: delAccountView sender is not a UIButton")
                return
            }
            self.performLogout(logOutTitle: delTitle, sender: button)
        }
        delAccountView!.title = delTitle
        delAccountView?.backgroundColor = .sesame2Gray
        contentStackView.addArrangedSubview(delAccountView!)
    }
    
    private func setupWebView() -> UIView {
        let collectionViewContainer = UIView(frame: .zero)
        let contentHeight = 60.0 + CGRectGetHeight(tabBarController!.tabBar.frame) + CGRectGetHeight(navigationController!.navigationBar.frame) + UIApplication.shared.statusBarHeight + 20
        collectionViewContainer.autoLayoutHeight(CGRectGetHeight(view.bounds) - contentHeight)
        let web = CHWebView.instanceWithScene("me-index")
        self.webView = web
        web.registerSchemeHandler("ssm://UI/webview/open") { [weak self] view, url, param in
            guard let self = self else {
                return
            }
            guard let urlStr = param["url"] else {
                return
            }
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(refreshMe), name: Notification.Name(notifyName), object: nil)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated:true)
        }
        web.registerMessageHandler(WebViewMessageType.requestLogin.rawValue) { webView, data in
            if let _ = data as? [String: Any] {
                self.performLogin()
            }
        }
        web.registerMessageHandler(WebViewMessageType.requestPushToken.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String {
                let token: String = UserDefaults.standard.string(forKey: "devicePushToken") ?? ""
                webView.callH5(funcName: callbackName, data: [
                    "pushToken": token
                ])
            }
        }
        collectionViewContainer.addSubview(web)
        web.autoPinEdgesToSuperview(safeArea: false)
        web.loadRequest()
        web.registerMessageHandlers()
        return collectionViewContainer
    }

    
    func performLogin() {
        let loginViewController = SignUpViewController.instance { isLoggedIn in
            if isLoggedIn {
                CHUserAPIManager.shared.getNickname { result in
                    // Set History tag
                    if case let .success(nickname) = result {
                        if nickname == nil {
                            CHUserAPIManager.shared.getEmail { getEmailResult in
                                if case let .success(email) = getEmailResult {
                                    let emailId = String(email!.split(separator: "@").first!)
                                    CHUserAPIManager.shared.updateNickname(emailId) { updateResult in
                                        executeOnMainThread {
                                            self.webView?.refresh()
                                        }
                                    }
                                }
                            }
                        } else {
                            executeOnMainThread {
                                self.webView?.refresh()
                            }
                        }
                        CHUserAPIManager.shared.getSubId { subId in
                            if let subId = subId, !subId.isEmpty {
                                let ss5history = CHUserAPIManager.shared.formatSubuuid(subId)
                                Sesame2Store.shared.setSubUuid(ss5history)
                            }
                        }
                    } else {
                        executeOnMainThread {
                            self.webView?.refresh()
                        }
                    }
                }
            }
        }
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    func performLogout(logOutTitle: String, sender: UIButton) {
        let preferredStyle: UIAlertController.Style = .actionSheet
        let alertController = UIAlertController(title: logOutTitle, message: nil, preferredStyle: preferredStyle)
        let signOut = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized, style: .destructive) { _ in
            // MARK: - Log out
            CHUserAPIManager.shared.signOut {
                CHDeviceManager.shared.setHistoryTag()
                Sesame2Store.shared.setSubUuid(Data())
                CHDeviceWrapperManager.shared.clear()
                executeOnMainThread { [weak self] in
                    self?.webView?.refresh()
                }
            }
        }
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(signOut)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true)
    }
    
}
