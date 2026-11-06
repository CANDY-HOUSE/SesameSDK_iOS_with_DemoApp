struct AppRoute: Equatable {
    let path: String
    let tab: Bool
    let modal: Bool

    var isRoot: Bool { tab && !modal }

    static let home = AppRoute(path: "/", tab: true, modal: false)

    init(path: String, tab: Bool, modal: Bool) {
        self.path = path
        self.tab = tab
        self.modal = modal
    }

    init(_ json: [String: Any]) {
        self.init(path: json["path"] as? String ?? "", tab: json["tab"] as? Bool ?? false, modal: json["modal"] as? Bool ?? false)
    }
}
