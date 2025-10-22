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
    
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_RADAR_PARAM_SET, payload)) { (response) in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    

}
