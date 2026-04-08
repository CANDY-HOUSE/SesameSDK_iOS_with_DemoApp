//
//  CHSesameBiometricDeviceImpl+Settings.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBiometricDeviceImpl {

    func registerHandlers(itemCode: SesameItemCode, payload: Data) -> Bool {
        var handle = false

        switch itemCode {
        case .mechStatus:
            handle = true
            mechStatus = CHSesameTouchProMechStatus.fromData(payload)!
            postBatteryData(payload[0..<2].toHexString()) { res in
                if case .success(let resp) = res {
                    self.notifyBatteryPercentageChanged(percentage: resp.data)
                }
            }

        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(payload.toHexString()) { _ in }

        case .pubKeySesame:
            handle = true
            var sesame2Keys = [String: String]()
            let dividedData = payload.divideArray(chunkSize: 23)

            for keyData in dividedData {
                let lockStatus = keyData[22]
                if lockStatus != 0 {
                    if keyData[21] == 0x00 {
                        let deviceIDData = keyData[0...15]
                        if let sesame2DeviceId = deviceIDData.toHexString().noDashtoUUID() {
                            sesame2Keys[sesame2DeviceId.uuidString] = "05"
                        }
                    } else {
                        let ss2Ir22 = keyData[0...21]
                        if let decodedData = Data(base64Encoded: (String(data: ss2Ir22, encoding: .utf8)! + "==")) {
                            if let sesame2DeviceId = decodedData.toHexString().noDashtoUUID() {
                                sesame2Keys[sesame2DeviceId.uuidString] = "04"
                            }
                        }
                    }
                }
            }

            self.sesame2Keys = sesame2Keys

            let hasEmptySlot: Bool
            if productModel == .openSensor || productModel == .openSensor2 {
                hasEmptySlot = dividedData.filter({ $0.allSatisfy({ $0 == 0x00 }) }).count > 1
            } else {
                hasEmptySlot = dividedData.contains(where: { $0.allSatisfy({ $0 == 0x00 }) })
            }

            if !hasEmptySlot {
                (self.delegate as? CHSesameConnectorDelegate)?.onSlotFull(device: self)
                notifySlotFull()
            }

        case .REMOTE_NANO_ITEM_CODE_PUB_TRIGGER_DELAYTIME:
            handle = true
            triggerDelaySetting = CHRemoteBaseTriggerSettings.fromData(payload)!
            (self.delegate as? CHRemoteNanoDelegate)?.onTriggerDelaySecondReceived(device: self, setting: triggerDelaySetting!)

        case .SSM_OS3_RADAR_PARAM_PUBLISH:
            handle = true
            radarPayload = Data(payload.bytes)

        case .SSM3_ITEM_CODE_SESAME_UNSUPPORT:
            handle = true
            (self.delegate as? CHSesameConnectorDelegate)?.onSSMSupport(device: self, isSupport: false)
            notifySSMSupport(isSupport: false)

        case .SSM3_ITEM_CODE_BLE_TX_POWER_SETTING:
            handle = true
            guard let value = payload.first else { return handle }
            bleTxPower = value

        default:
            handle = false
        }

        return handle
    }
}
