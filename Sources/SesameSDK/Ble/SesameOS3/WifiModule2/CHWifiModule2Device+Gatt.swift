//
//  WifiModule2Device+GattReceiver.swift
//  SesameSDK
//
//  Created by tse on 2023/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHWifiModule2Device {
    
    func parseNotifyPayload(_ data: Data) {
        let sesame2Notify = Sesame2NotifyPayload(data: data)
        if sesame2Notify.opCode == .publish {
            let publishPayload = WifiModule2PublishPayload(data: sesame2Notify.payload)
            onGattWifiModule2Publish(action: publishPayload.actionCode, data: publishPayload.payload)
        }
        if sesame2Notify.opCode == .response {
            let responsePayload = WifiModule2CmdResponsePayload(sesame2Notify.payload)
            onGattSesame2Response(responsePayload)
        }
    }
    private func onGattSesame2Response(_ payload: WifiModule2CmdResponsePayload) {
//        L.d("🀄","Res <==", payload.actionCode.plainName, payload.cmdResultCode.plainName)
        onResponseWm2?(payload)
        onResponseWm2 = nil
        semaphoreSesame?.signal()
    }
    
    private func onGattWifiModule2Publish(action: UInt8, data: Data) {

        switch WifiModule2ActionCode(rawValue: action)! {
        case .sesame2Keys:
            var sesame2Keys = [String: String]()
            let byteArray: Array = [UInt8](data)
            let keyDatas = stride(from: 0, to: byteArray.count, by: 23).map {
                Array(byteArray[$0 ..< Swift.min($0 + 23, byteArray.count)])
            }
//            L.d("data:" + data.toHexString())
            for keyData in keyDatas {
                let content = Data(bytes: keyData, count: keyData.count)
                let sesame2IR = content[0...21]
                let lockStatus = content[22...22]
                let base64EncodedIR = String(data: sesame2IR, encoding: .utf8)! + "=="
                if let sesame2DeviceId = Data(base64Encoded: base64EncodedIR)?.toHexString().noDashtoUUID() {
                    var lockStatusBool = lockStatus.copyData
                    sesame2Keys[sesame2DeviceId.uuidString] = "\(lockStatusBool.toUInt8())"
                }
            }
            self.sesame2Keys = sesame2Keys
//            L.d("wm2", "ble", "sesame2Keys", self.sesame2Keys)
        case .updateWifiSSID:
            let ssid = String(data: data, encoding: .utf8)
            mechSetting!.wifiSSID = ssid
            (delegate as? CHWifiModule2Delegate)?.onAPSettingChanged(device: self, settings: mechSetting!)
        case .updateWifiPassword:
            let password = String(data: data, encoding: .utf8)
            mechSetting!.wifiPassword = password
            (delegate as? CHWifiModule2Delegate)?.onAPSettingChanged(device: self, settings: mechSetting!)
        case .networkStatus:
            var content = data.copyData
            let isAp: Bool = (content[0...0].toInt8() & 2) > 0
            let isNet: Bool = (content[0...0].toInt8() & 4) > 0
            let isIoT: Bool = (content[0...0].toInt8() & 8) > 0
            let isAPCheck: Bool = (content[0...0].toInt8() & 16) > 0
            let isAPConnecting: Bool = (content[0...0].toInt8() & 32) > 0
            let isNETConnecting: Bool = (content[0...0].toInt8() & 64) > 0
            let isIOTConnecting: Bool = content[0...0].toInt8() < 0
            
//            L.d("🎾 isAp: \(isAp), isNet: \(isNet), isIoT: \(isIoT), isAPCheck: \(isAPCheck), isAPConnecting: \(isAPConnecting), isNETConnecting: \(isNETConnecting), isIOTConnecting: \(isIOTConnecting)")
            
            mechStatus = CHWifiModule2NetworkStatus(isAPWork: isAp, isNetwork: isNet, isIoTWork: isIoT, isBindingAPWork: isAPConnecting, isConnectingNetwork: isNETConnecting, isConnectingIoT: isIOTConnecting)
            
            if isRegistered {
                if isAPCheck {
                    if isIoT {
                        deviceStatus = CHDeviceStatus.iotConnected()
                    } else {
                        deviceStatus = CHDeviceStatus.iotDisconnected()
                    }
                } else {
                    deviceStatus = CHDeviceStatus.waitApConnect()
                }
            }
        case .initial:
//            sesame2Keys.removeAll()
            wifiModule2Token = data.copyData
            if isRegistered {
                login()
            } else {
                deviceStatus = CHDeviceStatus.readyToRegister()
            }
        case .none:
            break
        case .registerWM2:
            break
        case .loginWM2:
            break
        case .connectWifi:
            break
        case .deleteSesame2:
            break
        case .addSesame2:
            break
        case .cccd:
            break
        case .resetWM2:
            break
        case .versionTag:
            break
        case .openOTAServer:
            if var percentage = data[safeBound: 0...0]?.copyData {
                (delegate as? CHWifiModule2Delegate)?.onOTAProgress(device: self, percent: percentage.toUInt8())
            }
        case .scanWifiSSID:
            
            var rssiData = data[safeBound: 0...1]!.copyData
            let ssidData = data[2...]
            let rssi = rssiData.toInt16()
            let ssid = String(data: ssidData.copyData, encoding: .utf8)
            (delegate as? CHWifiModule2Delegate)?.onScanWifiSID(device: self, ssid: CHSSID(name: ssid!, rssi: rssi))
        }
    }
}

extension CHWifiModule2Device {
    func sendCommand(_ payload:WifiModule2Payload,
                     isCipher: SesameBleSegmentType = .ciphertext,
                     onResponse: WifiModule2ResponseCallback? = nil) {
        commandQueue.async() {
//            L.d("🀄", "藍芽", payload.itemCode.plainName, "semaphore 排隊")
            self.semaphoreSesame?.wait()
            self.onResponseWm2 = onResponse
            if isCipher == .ciphertext {
                self.gattTxBuffer =  SesameBleTransmiter(.ciphertext, try! payload.toDataWithHeader(withCipher: self.cipher!))
            } else {
                self.gattTxBuffer = SesameBleTransmiter(.plaintext, payload.toDataWithHeader())
            }
            self.transmit()
        }
    }

    /// Write value to peripheral.
    func transmit() {
        if self.peripheral == nil {
            return
        }
        if self.characteristic == nil {
            return
        }

        if let data = gattTxBuffer?.getChunk() {
            if data[0] > 0x01 {
                self.peripheral!.writeValue(data, for: self.characteristic!, type: .withResponse)
            } else {
                self.peripheral!.writeValue(data, for: self.characteristic!, type: .withoutResponse)
                transmit()
            }
        }
    }
}
