import UIKit
import WebKit

@MainActor
final class StartupCover {
    private(set) var active = true
    private var generation = 0
    private var timeout: DispatchWorkItem?
    private let cover = UIView()
    private let logo = UIImageView(image: UIImage(named: "LaunchLogo"))
    private let retryButton = UIButton(type: .system)

    init(in parent: UIView, retry: @escaping () -> Void) {
        cover.backgroundColor = .launchBackground
        cover.translatesAutoresizingMaskIntoConstraints = false
        logo.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)), for: .normal)
        retryButton.tintColor = .sesameGreen
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true
        retryButton.addAction(UIAction { [weak self] _ in
            guard let self, self.active else { return }
            self.begin()
            retry()
        }, for: .touchUpInside)
        cover.addSubview(logo)
        cover.addSubview(retryButton)
        parent.addSubview(cover)
        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: parent.topAnchor),
            cover.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            cover.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            cover.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            // Same size and position as the logo in LaunchScreen.storyboard, so the hand-off does not move.
            logo.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 140),
            logo.heightAnchor.constraint(equalToConstant: 140),
            retryButton.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: cover.centerYAnchor, constant: 120),
            retryButton.widthAnchor.constraint(equalToConstant: 56),
            retryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        begin()
    }

    func begin() {
        guard active else { return }
        generation += 1
        retryButton.isHidden = true
        timeout?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.showRetry() }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    func ready(_ web: WKWebView) {
        guard active else { return }
        let expected = generation
        web.callAsyncJavaScript(
            "await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));",
            arguments: [:], in: nil, in: .page
        ) { [weak self] _ in
            guard let self, self.active, expected == self.generation else { return }
            self.close()
        }
    }

    func fail() {
        guard active else { return }
        generation += 1
    }

    private func showRetry() {
        guard active else { return }
        retryButton.isHidden = false
    }

    func close() {
        guard active else { return }
        active = false
        generation += 1
        timeout?.cancel()
        UIView.animate(withDuration: 0.2, animations: { self.cover.alpha = 0 }) { _ in
            self.cover.removeFromSuperview()
        }
    }
}

extension UIColor {
    static let sesameGreen = UIColor(red: 0x28 / 255.0, green: 0xae / 255.0, blue: 0xb1 / 255.0, alpha: 1)
    // Same as the LaunchScreen.storyboard background and the Android system splash.
    static let launchBackground = UIColor(white: 0xf7 / 255.0, alpha: 1)
}
