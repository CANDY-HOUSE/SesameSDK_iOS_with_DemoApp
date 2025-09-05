// Sesame5HistoryViewController.swift
import UIKit
import SesameSDK
import SwiftUI

class SesameHistoryViewController: CHBaseViewController {

    // MARK: - Data model
    var sesame2: CHSesameLock!

    // MARK: - Callback
    var dismissHandler: (()->Void)?
    var settingClickHandler: (()->Void)?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
                if case let .success(urlStr) = result {
                    self.showWebView(urlString: urlStr.data)
                } else if case let .failure(error) = result {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
    
    private func showWebView(urlString: String) {
        let webViewScreen = WebViewScreen(urlString: urlString, isModal: false)
        let hostingController = UIHostingController(rootView: webViewScreen)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    // MARK: - Navigation (保留的唯一逻辑)
    @objc private func navigateToSesame2SettingView(_ sender: Any) {
        settingClickHandler?()
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
