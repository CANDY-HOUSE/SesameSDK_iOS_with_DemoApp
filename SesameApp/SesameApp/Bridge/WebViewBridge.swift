import Foundation
import SesameSDK
import WebKit

@MainActor
final class WebViewBridge: NSObject {
    typealias Reply = (_ success: Bool, _ data: Any?, _ error: String?) -> Void

    static let handlerName = "sesameNative"

    static let bootstrapScript = WKUserScript(source: """
        (() => {
            const queued = [];
            window.__sesameNativeEvents = queued;
            window.__sesameNativeReceive = (text) => { queued.push(text); };
            window.__sesameNativeConnect = () => { window.__sesameNativeConnected = true; };
        })();
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)

    private let origin: URL
    private let handle: ([String: Any], @escaping Reply) async -> Void
    private weak var webView: WKWebView?
    private var generation = 0
    private var connected = false
    private var documentTasks: [Task<Void, Never>] = []
    private var pending: [String: CheckedContinuation<Any?, Error>] = [:]

    init(origin: URL, handle: @escaping ([String: Any], @escaping Reply) async -> Void) {
        self.origin = origin
        self.handle = handle
    }

    func install(in controller: WKUserContentController) {
        controller.addUserScript(Self.bootstrapScript)
        controller.add(WeakScriptMessageHandler(self), name: Self.handlerName)
#if DEBUG
        controller.addUserScript(WKUserScript(source: """
            ['warn', 'error'].forEach((level) => {
                const original = console[level];
                console[level] = (...args) => {
                    try { window.webkit.messageHandlers.sesameConsole.postMessage(level + ' ' + args.map(String).join(' ').slice(0, 500)); } catch (_) {}
                    original.apply(console, args);
                };
            });
            window.addEventListener('error', (event) => {
                try { window.webkit.messageHandlers.sesameConsole.postMessage('uncaught ' + event.message); } catch (_) {}
            });
            window.addEventListener('unhandledrejection', (event) => {
                try { window.webkit.messageHandlers.sesameConsole.postMessage('unhandled ' + String(event.reason?.stack || event.reason).slice(0, 500)); } catch (_) {}
            });
            const originalFetch = window.fetch;
            window.fetch = (...args) => originalFetch(...args).then((response) => {
                if (!response.ok) window.webkit.messageHandlers.sesameConsole.postMessage('fetch ' + response.status + ' ' + String(response.url).split('?')[0]);
                return response;
            }, (error) => {
                window.webkit.messageHandlers.sesameConsole.postMessage('fetch failed ' + String(args[0]?.url || args[0]).split('?')[0] + ' ' + error);
                throw error;
            });
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        controller.add(ConsoleLogHandler(), name: "sesameConsole")
#endif
    }

    func isTrusted(_ url: URL?) -> Bool {
        guard let url else { return false }
        return isTrusted(scheme: url.scheme, host: url.host, port: url.port)
    }

    func isTrusted(_ securityOrigin: WKSecurityOrigin) -> Bool {
        isTrusted(scheme: securityOrigin.protocol, host: securityOrigin.host, port: securityOrigin.port == 0 ? nil : securityOrigin.port)
    }

    private func isTrusted(scheme: String?, host: String?, port: Int?) -> Bool {
        func defaultPort(_ scheme: String?) -> Int { scheme?.lowercased() == "https" ? 443 : 80 }
        return scheme?.lowercased() == origin.scheme?.lowercased() &&
            host?.lowercased() == origin.host?.lowercased() &&
            (port ?? defaultPort(scheme)) == (origin.port ?? defaultPort(origin.scheme))
    }

    func connect(_ view: WKWebView) {
        guard !connected, isTrusted(view.url) else { return }
        webView = view
        connected = true
        trace("connected")
        view.evaluateJavaScript("window.__sesameNativeConnect && window.__sesameNativeConnect()", completionHandler: nil)
    }

    func emit(_ type: String, _ data: Any = [String: Any]()) {
        guard connected, let view = webView, isTrusted(view.url),
              let message = try? JSONSerialization.data(withJSONObject: ["type": type, "data": data]),
              let text = String(data: message, encoding: .utf8),
              let literal = try? JSONSerialization.data(withJSONObject: text, options: .fragmentsAllowed),
              let argument = String(data: literal, encoding: .utf8) else { return }
        if type != "result" { trace("→ \(type)") }
        view.evaluateJavaScript("window.__sesameNativeReceive && window.__sesameNativeReceive(\(argument))", completionHandler: nil)
    }

    func requestCloud(_ operation: String, body: [String: Any], deviceUUID: String?) async throws -> Any? {
        guard connected else { throw BridgeError.pageUnavailable }
        let id = UUID().uuidString
        let epoch = generation
        let timeout = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            self?.pending.removeValue(forKey: id)?.resume(throwing: BridgeError.timeout)
        }
        defer { timeout.cancel() }
        return try await withCheckedThrowingContinuation { continuation in
            guard epoch == generation else {
                continuation.resume(throwing: BridgeError.pageChanged)
                return
            }
            pending[id] = continuation
            emit("cloudRequest", ["requestId": id, "op": operation, "body": body, "deviceUUID": deviceUUID.map { $0 as Any } ?? NSNull()])
        }
    }

    func reset() {
        generation += 1
        connected = false
        documentTasks.forEach { $0.cancel() }
        documentTasks.removeAll()
        let abandoned = pending.values
        pending.removeAll()
        abandoned.forEach { $0.resume(throwing: BridgeError.pageChanged) }
    }

    fileprivate func receive(_ message: WKScriptMessage) {
        guard connected, let view = webView, message.webView === view, message.frameInfo.isMainFrame,
              isTrusted(message.frameInfo.securityOrigin), isTrusted(view.url),
              let text = message.body as? String,
              let json = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] else { return }
        trace("← \(json["action"] as? String ?? "")")
        if json["action"] as? String == "home.cloudResponse" {
            guard let id = json["requestId"] as? String, let request = pending.removeValue(forKey: id) else { return }
            if json["success"] as? Bool == true {
                request.resume(returning: json["data"].flatMap { $0 is NSNull ? nil : $0 })
            } else {
                request.resume(throwing: BridgeError.cloudFailed)
            }
            return
        }
        let epoch = generation
        let requestId = json["requestId"] as? String ?? ""
        let action = json["action"] as? String ?? ""
        let task = Task { [weak self] in
            guard let self else { return }
            await self.handle(json) { [weak self] success, data, error in
                Task { @MainActor [weak self] in
                    guard let self, epoch == self.generation else { return }
                    self.trace("→ result \(action) \(success ? "ok" : "failed")")
                    self.emit("result", [
                        "requestId": requestId,
                        "success": success,
                        "data": data ?? NSNull(),
                        "error": error ?? NSNull()
                    ])
                }
            }
        }
        documentTasks.removeAll { $0.isCancelled }
        documentTasks.append(task)
    }

    /// Debug builds only; names of actions and events, never their payloads.
    private func trace(_ text: String) {
        L.d(text, tag: "Bridge")
    }

    enum BridgeError: Error {
        case pageUnavailable, pageChanged, timeout, cloudFailed
    }
}

@MainActor
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var bridge: WebViewBridge?

    init(_ bridge: WebViewBridge) {
        self.bridge = bridge
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        bridge?.receive(message)
    }
}

#if DEBUG
private final class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        L.d(message.body, tag: "Page")
    }
}
#endif
