//
//  CHSesameBaseDevice+Settings.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/3.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
extension CHSesameBaseDevice {
    
    func registerHandlers(itemCode: SesameItemCode,payload: Data) -> Bool {
        var handle = false
        
        switch itemCode {
        case .mechStatus:
            handle = true
            L.d("[TPO][mechStatus]",payload.toHexLog())
            mechStatus = CHSesameTouchProMechStatus.fromData(payload)!
            //            L.d("[TPO][電壓]",mechStatus?.getBatteryVoltage())
            L.d("[TPO][電量]",mechStatus?.getBatteryPrecentage())
            postBatteryData(payload[0..<2].toHexString())

        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(payload.toHexString())
        case .pubKeySesame:
            handle = true
            var sesame2Keys = [String: String]()
            let dividedData = payload.divideArray(chunkSize: 23)
            for keyData in dividedData {
                let lockStatus = keyData[22]
                //               L.d("lockStatus!!!",lockStatus)
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
            L.d("sesame2Keys",sesame2Keys)
            
        case .REMOTE_NANO_ITEM_CODE_PUB_TRIGGER_DELAYTIME:
            handle = true
            triggerDelaySetting = CHRemoteBaseTriggerSettings.fromData(payload)!
            L.d("REMOTE_NANO_ITEM_CODE_PUB_TRIGGER_DELAYTIME", payload.bytes)
            (self.delegate as? CHRemoteNanoDelegate)?.onTriggerDelaySecondReceived(device: self, setting: triggerDelaySetting!)
            
        case .SSM_OS3_RADAR_PARAM_PUBLISH:
            handle = true
            radarPayload = Data(payload.bytes)
            L.d("SSM_OS3_RADAR_PARAM_PUBLISH", payload.bytes)
            
        default:
            handle = false
        }
        
        return handle
    }
    
}
