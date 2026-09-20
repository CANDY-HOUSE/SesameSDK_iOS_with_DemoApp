//
//  Hub3TopicId.swift
//  SesameSDK
//
//  Hub 3 系列在 IoT topic / thing shadow name 裡使用的設備標識。
//

import Foundation

/// 舊 Hub 3 與 WM2 的 uuid 是「固定前綴 + MAC」拼出來的，
/// 韌體在 IoT topic 和 thing shadow name 裡只帶末段 MAC（12 字元）。
///
/// Hub 3 Pro 的 uuid 无前綴，韌體用的是**完整 uuid**（36 字元）。兩者混用會讓 App 訂到
/// 不存在的 topic，或在子設備影子裡寫出永遠清不掉的孤兒 key。
///
/// 與 Android 的 `hub3TopicId()`、後台 lambda、biz3 前端保持同一套約定。
///
/// - Note: 這裡用 productModel 判斷而不是比對 uuid 前綴。iOS 的
///   `subscribeWifiModule2Shadow` 是 WM2 / Hub 3 / Hub 3 Pro 共用的
/// - Parameters:
///   - deviceId: 設備 uuid
///   - productModel: 設備型號，決定用完整 uuid 還是末段 MAC
/// - Returns: 用於 topic / shadow name 的標識（大寫）
public func chHub3TopicId(_ deviceId: UUID, productModel: CHProductModel?) -> String {
    let uuidString = deviceId.uuidString.uppercased()
    guard productModel == .hub3Pro else {
        // WM2 / 舊 Hub 3：末段即 MAC
        return String(uuidString.split(separator: "-").last ?? "")
    }
    return uuidString
}
