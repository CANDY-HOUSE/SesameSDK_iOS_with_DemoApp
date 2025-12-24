//
//  CHHub3Device+Gatt.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/27.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation

extension CHHub3Device {
    
    func onGattHub3Publish(_ payload: SesameOS3PublishPayload) {
        let itemCode = payload.itemCode
        let data = payload.payload
        L.d("[Hub3][onGattHub3Publish]itemCode:",itemCode.rawValue,"data:", data.bytes)
        switch itemCode {
        case .mechSetting:
            guard data.count > 0 else { break }
            let endIndex = data.count == 60 ? 30 : 32
            mechSetting?.wifiSSID = String(data: data[0..<endIndex], encoding: .utf8)
            mechSetting?.wifiPassword = String(data: data[endIndex...], encoding: .utf8)
            (delegate as? CHWifiModule2Delegate)?.onAPSettingChanged(device: self, settings: mechSetting!)
        case .mechStatus:
            var content = data.copyData
            guard content.count > 0 else { break }
            let isAp: Bool = (content[0...0].toInt8() & 2) > 0
            let isNet: Bool = (content[0...0].toInt8() & 4) > 0
            let isIoT: Bool = (content[0...0].toInt8() & 8) > 0
            let isAPConnecting: Bool = (content[0...0].toInt8() & 32) > 0
            let isNETConnecting: Bool = (content[0...0].toInt8() & 64) > 0
            let isIOTConnecting: Bool = content[0...0].toInt8() < 0
            mechStatus = CHWifiModule2NetworkStatus(isAPWork: isAp, isNetwork: isNet, isIoTWork: isIoT, isBindingAPWork: isAPConnecting, isConnectingNetwork: isNETConnecting, isConnectingIoT: isIOTConnecting)
        case .HUB3_ITEM_CODE_SSID_FIRST:break
        case .HUB3_ITEM_CODE_SSID_LAST: break
        case .HUB3_ITEM_CODE_SSID_NOTIFY:
            guard data.count > 1 else { break }
            var rssiData = data[safeBound: 0...1]!.copyData
            let ssidData = data[2...]
            let rssi = rssiData.toInt16()
            if let ssid = String(data: ssidData.copyData, encoding: .utf8) {
                (delegate as? CHWifiModule2Delegate)?.onScanWifiSID(device: self, ssid: CHSSID(name: ssid, rssi: rssi))
            }
        default:
            L.d("!![hub3][pub][\(itemCode.rawValue)]")
        }
    }
    
    func updateMechSettingStatusAndKeys(_ status: Hub3Status) {
        self.status = status
        mechSetting?.wifiSSID = status.wifi_ssid
        mechSetting?.wifiPassword = status.wifi_password
        (delegate as? CHWifiModule2Delegate)?.onAPSettingChanged(device: self, settings: mechSetting!)
        
        let isConnectIOT = status.eventType == "connected" // 判断是否连接到IOT
        mechStatus = CHWifiModule2NetworkStatus(
            isAPWork: isConnectIOT,
            isNetwork: isConnectIOT,
            isIoTWork: isConnectIOT,
            isBindingAPWork: false,
            isConnectingNetwork: false,
            isConnectingIoT: false
        )
        
        guard let ssks = status.ssks else {
            return
        }
        var result: [String: String] = [:]
        let chunkSize = 38
        let valueSize = 36
        for (index, chunk) in stride(from: 0, to: ssks.count, by: chunkSize).enumerated() {
            let startIndex = ssks.index(ssks.startIndex, offsetBy: chunk)
            let endIndex = ssks.index(startIndex, offsetBy: min(valueSize, ssks.count - chunk))
            let substring = String(ssks[startIndex..<endIndex])
            if substring.count == valueSize {
                result[substring] = "\(index)"
            }
        }
        self.sesame2Keys = result
    }
}
