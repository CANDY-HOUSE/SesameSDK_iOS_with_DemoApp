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

        case .pubKeySesame:
            var sesame2Keys = [String: String]()
            let dividedData = data.divideArray(chunkSize: 23)
            for (index, keyData) in dividedData.enumerated() {
                let lockStatus = keyData[22]
                // L.d("lockStatus!!!",lockStatus)
                if lockStatus != 0 {
                    let deviceIDData = keyData[0...15]
                    if let sesame2DeviceId = deviceIDData.toHexString().noDashtoUUID() {
                        sesame2Keys[sesame2DeviceId.uuidString] = "\(index)"///hub3 不兼容老设备，这里不消费锁状态，value 用来排序
                    }
                }
            }
            self.sesame2Keys = sesame2Keys
            L.d("sesame2Keys",sesame2Keys)
        case .moveTo:
            if var percentage = data[safeBound: 0...0]?.copyData {
                L.d("[hub3 ] ota ",percentage)
                (delegate as? CHWifiModule2Delegate)?.onOTAProgress(device: self, percent: percentage.toUInt8())
            }
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
        // 模式匹配语法，判断是否属于Hub3ItemCode.HUB3_ITEM_CODE_LED_DUTY
        case _ where itemCode.rawValue == Hub3ItemCode.HUB3_ITEM_CODE_LED_DUTY.rawValue:
            self.hub3Brightness = data.uint8
            (delegate as? CHHub3Delegate)?.onHub3BrightnessReceive(device: self, brightness: data.uint8)
        default:
            L.d("!![hub3][pub][\(itemCode.rawValue)]")
        }
    }
    
    private func incrementProgress(newPosition: UInt8, updateHandler: @escaping (UInt8) -> Void) {
        guard progress.target > progress.current else {
            L.d("Target must be greater than start")
            return
        }
        var currentProgress = progress.current
        if progressTimer != nil {
            progressTimer?.invalidate()
            progressTimer = nil
        }
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            currentProgress += 1
            if currentProgress >= self.progress.target {
                timer.invalidate()
            }
            updateHandler(currentProgress)
        }
    }
    
    func updateFirmwareProgress(_ data: Data) {
        guard var percentage = data[safeBound: 0...0]?.copyData else {
            return
        }
        let recvProgress = percentage.toUInt8()
        progress.target = recvProgress
        incrementProgress(newPosition: recvProgress) { [self] val in
            progress.current = val
            (delegate as? CHWifiModule2Delegate)?.onOTAProgress(device: self, percent: val)
        }
    }
    
    func updateComplete(newVer: String) {
        if newVer != status.v {        
            status.hub3LastFirmwareVer = newVer
            status.v = status.hub3LastFirmwareVer
        }
        if progressTimer != nil {
            progressTimer?.invalidate()
            progressTimer = nil
            progress = (current: 0, target: 0)
            (delegate as? CHWifiModule2Delegate)?.onOTAProgress(device: self, percent: 100)
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
