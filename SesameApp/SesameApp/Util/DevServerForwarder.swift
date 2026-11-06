#if DEBUG
import Network
import SesameSDK

/// A device's own localhost is not the Mac, so localhost:3000 is forwarded to the Biz dev server on the Mac, like adb reverse.
/// The page keeps the http://localhost:3000 origin, which is a secure context and in the cloud's allowed origins.
final class DevServerForwarder {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "DevServerForwarder")

    init?(macIP: String, onReady: @escaping () -> Void) {
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback
        guard let listener = try? NWListener(using: parameters, on: 3000) else { return nil }
        self.listener = listener
        let target = NWEndpoint.hostPort(host: NWEndpoint.Host(macIP), port: 3000)
        listener.newConnectionHandler = { [queue] inbound in
            let outbound = NWConnection(to: target, using: .tcp)
            var closed = 0
            let close = {
                closed += 1
                if closed == 2 {
                    inbound.cancel()
                    outbound.cancel()
                }
            }
            // Offline, a connection to the Mac waits for a network path instead of failing, and the page's request would hang.
            // Reset it so the page's offline fallback (Service Worker cache) takes over, as a refused connection would.
            outbound.stateUpdateHandler = { state in
                switch state {
                case .waiting, .failed:
                    inbound.cancel()
                    outbound.cancel()
                default:
                    break
                }
            }
            Self.pipe(from: inbound, to: outbound, close: close)
            Self.pipe(from: outbound, to: inbound, close: close)
            inbound.start(queue: queue)
            outbound.start(queue: queue)
        }
        listener.stateUpdateHandler = { state in
            L.d("listener \(state)", tag: "DevServer")
            switch state {
            case .ready, .failed:
                // Still load on failure (e.g. the simulator, where the Mac's own dev server holds port 3000).
                DispatchQueue.main.async(execute: onReady)
            default:
                break
            }
        }
        listener.start(queue: queue)
    }

    private static func pipe(from source: NWConnection, to destination: NWConnection, close: @escaping () -> Void) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data, !data.isEmpty {
                destination.send(content: data, completion: .contentProcessed { _ in })
            }
            if let error {
                L.d("forward \(error)", tag: "DevServer")
                source.cancel()
                destination.cancel()
            } else if isComplete {
                destination.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in close() })
            } else {
                pipe(from: source, to: destination, close: close)
            }
        }
    }
}
#endif
