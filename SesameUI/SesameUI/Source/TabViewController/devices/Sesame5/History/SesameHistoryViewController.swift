// Sesame5HistoryViewController.swift
import UIKit
import SesameSDK
import WebKit

class SesameHistoryViewController: CHBaseViewController {
    var sesame2: CHDevice!
    var dismissHandler: (() -> Void)?
    var settingClickHandler: (() -> Void)?
    
    private weak var webView: CHWebView!
    
    deinit {
        webView?.cleanup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = sesame2.deviceName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupWebView()
    }
    
    private func setupNavigationBar() {
        if settingClickHandler != nil {
            setNavigationRightItem("icons_filled_more", #selector(navigateToSesame2SettingView(_:)))
        }
    }
    
    private func setupWebView() {
        let webView = CHWebView.instanceWithScene("history",
                                           extInfo: ["deviceUUID": sesame2.deviceId.uuidString])
        self.webView = webView
        view.addSubview(webView)
        webView.loadRequest()
        webView.autoPinEdgesToSuperview()
    }
    
    @objc private func navigateToSesame2SettingView(_ sender: Any) {
        settingClickHandler?()
    }
}

// MARK: - Designated initializer
extension SesameHistoryViewController {
    static func instance(_ sesame5: CHDevice, dismissHandler: (()->Void)?, settingClickHandler: (()->Void)?) -> SesameHistoryViewController {
        let sesameHistoryViewController = SesameHistoryViewController(nibName: nil, bundle: nil)
        sesameHistoryViewController.hidesBottomBarWhenPushed = true
        sesameHistoryViewController.sesame2 = sesame5
        sesameHistoryViewController.dismissHandler = dismissHandler
        sesameHistoryViewController.settingClickHandler = settingClickHandler
        return sesameHistoryViewController
    }
}
