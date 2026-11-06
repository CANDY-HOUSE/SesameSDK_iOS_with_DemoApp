import Foundation
import SesameSDK

enum BotSettings {
    @MainActor
    static func handle(_ ble: BleController, _ json: [String: Any]) async throws -> [String: Any] {
        guard let device = ble.device(json["deviceUUID"] as? String ?? "") as? CHSesameBot2 else { throw BleError.unsupported }
        try require(device.loggedIn)
        let index = json["index"] as? Int ?? -1
        try require((0...9).contains(index))
        switch json["operation"] as? String {
        case "read":
            let event: CHSesamebot2Event = try await bleResult(timeout: 8) { device.getCurrentScript(index: UInt8(index), result: $0) }
            return [
                "nameLength": Int(event.nameLength),
                "name": event.name.map(Int.init),
                "actions": (event.actions ?? []).map { ["type": Int($0.action.rawValue), "time": Int($0.time)] }
            ]
        case "select":
            let _: CHEmpty = try await bleResult(timeout: 8) { device.selectScript(index: UInt8(index), result: $0) }
            let _: CHSesamebot2Status? = try? await bleResult(timeout: 8) { device.getScriptNameList(result: $0) }
            ble.snapshot()
            return [:]
        case "write":
            let name = json["name"] as? [Int] ?? []
            let length = json["nameLength"] as? Int ?? -1
            let actions = json["actions"] as? [[String: Any]] ?? []
            try require((0...20).contains(length) && (length...20).contains(name.count) && actions.count <= 20)
            var payload = Data(count: 22 + actions.count * 2)
            payload[0] = UInt8(length)
            for (offset, value) in name.enumerated() {
                try require((0...255).contains(value))
                payload[1 + offset] = UInt8(value)
            }
            payload[21] = UInt8(actions.count)
            for (offset, item) in actions.enumerated() {
                let type = item["type"] as? Int ?? -1
                let time = item["time"] as? Int ?? -1
                try require((0...3).contains(type) && (0...255).contains(time))
                payload[22 + offset * 2] = UInt8(type)
                payload[23 + offset * 2] = UInt8(time)
            }
            let _: CHEmpty = try await bleResult(timeout: 8) { device.sendClickScript(index: UInt8(index), script: payload, result: $0) }
            return ["actionData": payload.map { String(format: "%02x", $0) }.joined()]
        default:
            throw BleError.unsupported
        }
    }
}
