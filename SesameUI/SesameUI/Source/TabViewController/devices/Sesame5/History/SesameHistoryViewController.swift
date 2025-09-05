// Sesame5HistoryViewController.swift
import UIKit
import SesameSDK
import WebKit

class SesameHistoryViewController: CHBaseViewController {

    // MARK: - Data model
    var sesame2: CHSesameLock!

    // MARK: - Callback
    var dismissHandler: (()->Void)?
    var settingClickHandler: (()->Void)?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setNavigationRightItem("icons_filled_more", #selector(navigateToSesame2SettingView(_:)))
        loadWebView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = sesame2.deviceName
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            dismissHandler?()
        }
    }

    // MARK: - WebView Loading
    private func loadWebView() {
        CHUserAPIManager.shared.getWebUrlByScene(scene: "history", extInfo: [
            "deviceUUID": sesame2.deviceId.uuidString,
        ]) { [weak self] result in
            executeOnMainThread {
                guard let self = self else { return }
                ViewHelper.hideLoadingView(view: self.view)
                if case let .success(urlStr) = result {
                    self.setupWebView(urlString: urlStr.data)
                } else if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

    // MARK: - Navigation
    @objc private func navigateToSesame2SettingView(_ sender: Any) {
        settingClickHandler?()
    }
}

// MARK: - WebView Setup
extension SesameHistoryViewController {
    private func setupWebView(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        if #available(iOS 17.4, *) {
            webView.scrollView.bouncesVertically = false
        }
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        webView.autoPinEdgesToSuperview()
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate
extension SesameHistoryViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        ViewHelper.showLoadingInView(view: view)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ViewHelper.hideLoadingView(view: view)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ViewHelper.hideLoadingView(view: view)
        self.view.makeToast(error.errorDescription())
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        ViewHelper.hideLoadingView(view: view)
        self.view.makeToast(error.errorDescription())
    }
}

// MARK: - Designated initializer
extension SesameHistoryViewController {
    static func instance(_ sesame5: CHSesameLock, dismissHandler: (()->Void)?, settingClickHandler: (()->Void)?) -> SesameHistoryViewController {
        let sesameHistoryViewController = SesameHistoryViewController(nibName: nil, bundle: nil)
        sesameHistoryViewController.hidesBottomBarWhenPushed = true
        sesameHistoryViewController.sesame2 = sesame5
        sesameHistoryViewController.dismissHandler = dismissHandler
        sesameHistoryViewController.settingClickHandler = settingClickHandler
        return sesameHistoryViewController
    }
}
