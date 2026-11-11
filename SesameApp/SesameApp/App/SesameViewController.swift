import CoreBluetooth
import Network
import SesameSDK
import UIKit
import WebKit

final class SesameViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
    private var web: WKWebView!
    private var bridge: WebViewBridge!
    private var requests: NativeRequestHandler!
    private var startupCover: StartupCover!
    private var externalPage: ExternalPage?
    private var startupDocumentFailed = false
    private var currentRoute = AppRoute.home
    private var observers: [NSObjectProtocol] = []
    private let ble = BleController.shared
    private let registration = BleRegistrationController()
    private var bleRequested = false
    private var webReady = false
    private var discovering = false
    private let network = NWPathMonitor()
#if DEBUG
    private var devServerForwarder: DevServerForwarder?
#endif

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        connectBridge()
        createWebView()
        startupCover = StartupCover(in: view) { [weak self] in
            self?.reloadEntry()
        }
        addBackGesture()
        observeLifecycle()
        retryStartupWhenOnline()
#if DEBUG
        if let macIP = AppConfig.devMacIP {
            devServerForwarder = DevServerForwarder(macIP: macIP) { [weak self] in
                self?.web.load(URLRequest(url: AppConfig.entry))
            }
            return
        }
#endif
        web.load(URLRequest(url: AppConfig.entry))
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        network.cancel()
    }

    private func reloadEntry() {
        startupDocumentFailed = false
        bridge.reset()
        web.stopLoading()
        web.load(URLRequest(url: AppConfig.entry))
    }

    // On a fresh install the entry load fails while the system network permission prompt is still open.
    private func retryStartupWhenOnline() {
        network.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            DispatchQueue.main.async {
                guard let self, self.startupCover.active, self.startupDocumentFailed else { return }
                self.reloadEntry()
            }
        }
        network.start(queue: DispatchQueue(label: "SesameViewController.network"))
    }

    private func connectBridge() {
        requests = NativeRequestHandler(host: .init(
            language: { Locale.preferredLanguages.first ?? Locale.current.identifier },
            uiReady: { [weak self] in
                guard let self, !self.startupDocumentFailed else { return }
                self.startupCover.ready(self.web)
            },
            snapshot: { [weak self] in self?.ble.snapshot() },
            showRoute: { [weak self] in self?.currentRoute = $0 },
            openWebPage: { [weak self] in self?.openWebPage($0) },
            openExternal: { UIApplication.shared.open($0) },
            haptic: { duration in
                // A timed vibration on Android; the former native lock tap used .heavy. Untimed is a slider tick.
                UIImpactFeedbackGenerator(style: duration > 0 ? .heavy : .light).impactOccurred()
            },
            requestBle: { [weak self] in self?.requestBle() },
            startDiscovery: { [weak self] in
                self?.discovering = true
                self?.requestBle()
            },
            stopDiscovery: { [weak self] in
                self?.discovering = false
                self?.registration.stop()
            },
            presenter: { [weak self] in self }
        ), ble: ble, registration: registration)
        bridge = WebViewBridge(origin: AppConfig.webOrigin) { [weak self] json, reply in
            await self?.requests.handle(json, reply: reply)
        }
        ble.publish = { [weak self] in self?.emit("snapshot", $0) }
        registration.publish = { [weak self] in self?.emit("discovery", $0) }
        registration.registered = { device in
            if let key = device.getKey() { KeyHandoff.add(key) }
        }
        PushManager.shared.changed = { [weak self] in self?.emit("push") }
        PushManager.shared.open = { [weak self] target in
            guard let self, self.webReady else { return false }
            switch target {
            case .route(let route):
                self.externalPage?.close()
                self.emit("navigate", route)
            case .webPage(let url):
                self.openWebPage(url)
            }
            return true
        }
        AutoUnlock.shared.permissionChanged = { [weak self] in self?.emit("locationPermission") }
        BleBackend.shared.requestCloud = { [weak self] operation, body, deviceUUID in
            guard let bridge = self?.bridge else { throw WebViewBridge.BridgeError.pageUnavailable }
            return try await bridge.requestCloud(operation, body: body, deviceUUID: deviceUUID)
        }
    }

    private func requestBle() {
        bleRequested = true
        if CBCentralManager.authorization == .denied || CBCentralManager.authorization == .restricted {
            emit("error", "Permission denied")
            return
        }
        guard UIApplication.shared.applicationState != .background else { return }
        ble.resume()
        if discovering { registration.start() }
    }

    private func createWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.applicationNameForUserAgent = "Mobile/15E148 SesameiOS/1"
        // Face3 live view opened from a doorbell push must start with the saved speaker setting.
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        bridge.install(in: configuration.userContentController)
        web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = false
#if DEBUG
        if #available(iOS 16.4, *) { web.isInspectable = true }
#endif
        web.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(web, at: 0)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: guide.topAnchor),
            web.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
    }

    private func emit(_ type: String, _ data: Any = [String: Any]()) {
        bridge.emit(type, data)
    }

    private func addBackGesture() {
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgeSwiped(_:)))
        edge.edges = .left
        edge.delegate = self
        view.addGestureRecognizer(edge)
    }

    @objc private func edgeSwiped(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended, gesture.translation(in: view).x > 60 else { return }
        handleBack()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    private func handleBack() {
        if let externalPage {
            externalPage.back()
        } else if !currentRoute.isRoot {
            emit("back")
        }
    }

    private func openWebPage(_ url: URL) {
        externalPage?.close()
        externalPage = ExternalPage(url: url, in: view, openExternal: { UIApplication.shared.open($0) }) { [weak self] in
            self?.externalPage = nil
        }
    }

    private func observeLifecycle() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            AutoUnlock.shared.refreshNotificationSetting()
            if self.bleRequested { self.requestBle() }
            self.emit("resume")
        })
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.emit("pause")
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.registration.stop()
            self?.ble.pause()
        })
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.targetFrame?.isMainFrame != false, let url = navigationAction.request.url else {
            return decisionHandler(.allow)
        }
        if bridge.isTrusted(url) {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                return decisionHandler(.cancel)
            }
            return decisionHandler(.allow)
        }
        if ["https", "http", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame, let response = navigationResponse.response as? HTTPURLResponse, response.statusCode >= 400 {
            startupDocumentFailed = true
            startupCover.fail()
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startupDocumentFailed = false
        startupCover.begin()
        bridge.reset()
        registration.close()
        ble.peripheralSettings.close()
        discovering = false
        webReady = false
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if startupCover.active, !startupDocumentFailed {
            bridge.connect(webView)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        bridge.connect(webView)
        webReady = true
        PushManager.shared.deliverPending()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        documentFailed(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        documentFailed(error)
    }

    private func documentFailed(_ error: Error) {
        let error = error as NSError
        // A navigation replaced by another one (or cancelled by policy) is not a failed document.
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled { return }
        if error.domain == WKError.errorDomain && error.code == 102 { return }
        L.d("document failed \(error.domain) \(error.code) \(error.localizedDescription)", tag: "Page")
        startupDocumentFailed = true
        startupCover.fail()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        startupCover.begin()
        bridge.reset()
        externalPage?.close()
        webView.load(URLRequest(url: AppConfig.entry))
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        nil
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(frame.isMainFrame && bridge.isTrusted(origin) ? .grant : .deny)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}
