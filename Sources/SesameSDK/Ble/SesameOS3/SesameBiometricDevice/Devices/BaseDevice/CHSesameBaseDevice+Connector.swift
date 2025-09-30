//
//  CHSesameBaseDevice+Connector.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesameBaseDevice {
    
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>) {
//        L.d("[TouchDevice][insertCHDevice]")
        if (!self.isBleAvailable(result)) { return }
        if device is CHSesameOS3 {
            let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            let noDashUUIDData = noDashUUID.hexStringtoData()
            let ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
            sendCommand(.init(.addSesame, noDashUUIDData+ssmSecKa)) { (response) in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        } else {
            let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            var base64Key = noDashUUID.hexStringtoData().base64EncodedString()
            base64Key = base64Key.replacingOccurrences(of: "=", with: "", options: [], range: nil)
            let sesame2IR = base64Key.data(using: .utf8)!
            let publicKeyData = device.getKey()!.sesame2PublicKey.hexStringtoData()
            let ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
            let allKey = sesame2IR + publicKeyData + ssmSecKa
            sendCommand(.init(.addSesame, allKey)) { (response) in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }
    }

    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("self.sesame2Keys[tag]",self.sesame2Keys[tag])
        if let lockStatusData = self.sesame2Keys[tag], let lockStatus = UInt8(lockStatusData), lockStatus == 0x04 {
            L.d("移除 ss4")

            let noDashUUID = tag.replacingOccurrences(of: "-", with: "")
            let base64String = noDashUUID.hexStringtoData().base64EncodedString().replacingOccurrences(of: "=", with: "")
            let ssmIRData = Data(base64String.utf8)
            sendCommand(.init(.removeSesame,ssmIRData)) { (response) in
                L.d("移除 ss4 ok")
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }

        } else {
            L.d("移除 ss5")
            let noDashUUID = tag.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            sendCommand(.init(.removeSesame,noDashUUID.hexStringtoData())) { (response) in
                L.d("移除 ss5 ok")
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }

    }
    
    func goIoTWithOpenSensor() {
        let topic = "opensensor/\(deviceId.uuidString.uppercased())"
        CHIoTManager.shared.subscribeTopic(topic) { data in
            do {
                let state = try JSONDecoder().decode(OpenSensorData.self, from: data)
                let mechState = OpensensorMechStatus.fromData(state)
                self.mechStatus = mechState
                L.d("CHSesameBaseDevice", "goIoTWithOpenSensor \(self.mechStatus?.getBatteryPrecentage() ?? 0)%")
            } catch {
                L.d("CHSesameBaseDevice", "Failed to decode: \(error)")
            }
        }
    }
    
    func subscribeBatteryTopic() {
        let topic = "battery/\(deviceId.uuidString.uppercased())"
        
        CHIoTManager.shared.subscribeTopic(topic) { [weak self] data in
            guard let self = self else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let voltageValue = json["lightLoadBatteryVoltage_mV"] as? NSNumber {
                    
                    let voltage = UInt16(voltageValue.intValue)
                    // 将 voltage 转换为反序字节（与 Android 的 toReverseBytes 一致）
                    let batteryData = Data([
                        UInt8(voltage & 0xFF),        // 低字节在前
                        UInt8((voltage >> 8) & 0xFF)  // 高字节在后
                    ])
                    
                    // 构造完整的 7 字节 Data（battery:2 + target:2 + position:2 + flags:1）
                    let fullData = batteryData + Data(repeating: 0, count: 5)
                    self.mechStatus = CHSesameTouchProMechStatus.fromData(fullData)!
                    L.d("CHSesameBaseDevice", "subscribeBatteryTopic \(self.mechStatus?.getBatteryPrecentage() ?? 0)%")
                }
            } catch {
                L.d("CHSesameBaseDevice", "Failed to parse: \(error)")
            }
        }
    }
    
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_RADAR_PARAM_SET, payload)) { (response) in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    

}
