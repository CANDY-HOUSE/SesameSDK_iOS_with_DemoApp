import Foundation
import UIKit

enum AppConfig {
    static let webOrigin: URL = {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "SesameWebHost") as? String,
              let url = URL(string: host == "localhost" ? "http://localhost:3000" : "https://\(host)"), url.host != nil else {
            fatalError("SesameWebHost is missing from Info.plist")
        }
        return url
    }()

#if DEBUG
    static var devMacIP: String? {
        guard let ip = Bundle.main.object(forInfoDictionaryKey: "SesameDevMacIP") as? String, !ip.isEmpty else { return nil }
        return ip
    }
#endif

    static var entry: URL {
        var components = URLComponents(url: webOrigin, resolvingAgainstBaseURL: false)!
        components.path = "/"
        components.queryItems = [URLQueryItem(name: "appHome", value: "1"), URLQueryItem(name: "fromType", value: "app")]
        return components.url!
    }

    static var versionName: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    static var versionCode: Int { Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0 }

    static var gitHash: String {
        guard let url = Bundle.main.url(forResource: "git", withExtension: "plist"),
              let plist = NSDictionary(contentsOf: url) else { return "" }
        return plist["GitCommit"] as? String ?? ""
    }

    static var buildType: String {
#if DEBUG
        "debug"
#else
        "release"
#endif
    }

    static var model: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    static var display: String {
        "\(versionName)(\(versionCode))-\(gitHash)-\(buildType)-\(model):\(UIDevice.current.systemVersion)"
    }
}
