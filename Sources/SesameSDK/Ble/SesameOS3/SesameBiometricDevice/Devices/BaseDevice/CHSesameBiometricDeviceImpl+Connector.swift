//
//  CHSesameBiometricDeviceImpl+Connector.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBiometricDeviceImpl {

    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }

        if device is CHSesameOS3 {
            let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            let noDashUUIDData = noDashUUID.hexStringtoData()
            let ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
            sendCommand(.init(.addSesame, noDashUUIDData + ssmSecKa)) { _ in
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
            sendCommand(.init(.addSesame, allKey)) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }
    }

    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }

        if let lockStatusData = self.sesame2Keys[tag],
           let lockStatus = UInt8(lockStatusData),
           lockStatus == 0x04 {

            let noDashUUID = tag.replacingOccurrences(of: "-", with: "")
            let base64String = noDashUUID.hexStringtoData().base64EncodedString().replacingOccurrences(of: "=", with: "")
            let ssmIRData = Data(base64String.utf8)

            sendCommand(.init(.removeSesame, ssmIRData)) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }

        } else {
            let noDashUUID = tag.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            sendCommand(.init(.removeSesame, noDashUUID.hexStringtoData())) { _ in
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
            } catch {
                L.d("CHSesameBiometricDeviceImpl", "Failed to decode: \(error)")
            }
        }
    }

    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_RADAR_PARAM_SET, payload)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func setBleTxPower(txPower: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if !isBleAvailable(result) { return }

        sendCommand(.init(.SSM3_ITEM_CODE_BLE_TX_POWER_SETTING, Data([txPower]))) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
}
