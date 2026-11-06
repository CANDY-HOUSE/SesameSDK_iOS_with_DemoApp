import Foundation
import SesameSDK

/// BLE primitives of the Biz internal test page; the loop, counter and UI live in Biz.
enum InternalTest {
    private static let firmwareDirKey = "firmwareDir"

    static var firmwareDir: String { UserDefaults.standard.string(forKey: firmwareDirKey) ?? "prod" }

    static func handle(_ ble: BleController, _ json: [String: Any], reply: @escaping WebViewBridge.Reply) {
        switch json["operation"] as? String {
        case "devices":
            reply(true, ble.allDevices().compactMap { device -> [String: Any]? in
                switch device {
                case is CHSesame5: return ["deviceUUID": device.uuid, "action": "toggle"]
                case is CHSesameBot2: return ["deviceUUID": device.uuid, "action": "click"]
                default: return nil
                }
            }, nil)
        case "run":
            let done: CHResult<CHEmpty> = { result in
                DispatchQueue.main.async {
                    if case .success = result { reply(true, nil, nil) } else { reply(false, nil, "Bluetooth command failed") }
                }
            }
            switch ble.device(json["deviceUUID"] as? String ?? "") {
            case let lock as CHSesame5: lock.toggle(historytag: ble.os3HistoryTag(), result: done)
            case let bot as CHSesameBot2: bot.click(index: nil, historytag: ble.os3HistoryTag(), result: done)
            default: reply(false, nil, "Unsupported device")
            }
        case "firmwareDir":
            if let value = json["value"] as? String {
                guard ["prod", "dev"].contains(value) else { return reply(false, nil, "Invalid firmware directory") }
                UserDefaults.standard.set(value, forKey: firmwareDirKey)
            }
            reply(true, ["firmwareDir": firmwareDir], nil)
        default:
            reply(false, nil, "Unsupported internal test operation")
        }
    }
}
