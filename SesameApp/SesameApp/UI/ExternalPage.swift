import UIKit
import WebKit

@MainActor
final class ExternalPage: NSObject, WKNavigationDelegate {
    private let container = UIView()
    private let web: WKWebView
    private let progress = UIActivityIndicatorView(style: .large)
    private let openExternal: (URL) -> Void
    private let closed: () -> Void

    init(url: URL, in parent: UIView, openExternal: @escaping (URL) -> Void, closed: @escaping () -> Void) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        web = WKWebView(frame: .zero, configuration: configuration)
        self.openExternal = openExternal
        self.closed = closed
        super.init()
        container.backgroundColor = .white
        container.translatesAutoresizingMaskIntoConstraints = false
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        back.tintColor = .darkText
        back.accessibilityLabel = "Back"
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addAction(UIAction { [weak self] _ in self?.back() }, for: .touchUpInside)
        web.translatesAutoresizingMaskIntoConstraints = false
        web.navigationDelegate = self
        progress.color = .sesameGreen
        progress.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(back)
        container.addSubview(web)
        container.addSubview(progress)
        parent.addSubview(container)
        let guide = parent.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: guide.topAnchor),
            container.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            back.topAnchor.constraint(equalTo: container.topAnchor),
            back.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            back.widthAnchor.constraint(equalToConstant: 48),
            back.heightAnchor.constraint(equalToConstant: 48),
            web.topAnchor.constraint(equalTo: back.bottomAnchor),
            web.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progress.centerXAnchor.constraint(equalTo: web.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: web.centerYAnchor)
        ])
        progress.startAnimating()
        web.load(URLRequest(url: url))
    }

    func back() {
        if web.canGoBack {
            web.goBack()
        } else {
            close()
        }
    }

    func close() {
        guard container.superview != nil else { return }
        web.stopLoading()
        web.navigationDelegate = nil
        container.removeFromSuperview()
        closed()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.targetFrame?.isMainFrame != false, let url = navigationAction.request.url else {
            return decisionHandler(.allow)
        }
        switch url.scheme?.lowercased() {
        case "https":
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                return decisionHandler(.cancel)
            }
            decisionHandler(.allow)
        case "http", "mailto", "tel":
            openExternal(url)
            decisionHandler(.cancel)
        default:
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progress.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progress.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progress.stopAnimating()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        close()
    }

}
