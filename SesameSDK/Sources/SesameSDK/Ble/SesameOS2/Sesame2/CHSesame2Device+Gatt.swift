//
//  Sesame2BleDeviceGattRx.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/08/19.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
extension CHSesame2Device {

    func parseNotifyPayload(_ data: Data) {
        let sesame2Notify = Sesame2NotifyPayload(data: data)
        if sesame2Notify.opCode == .publish {
            if let publishPayload = SesameOS3PublishPayload(data: sesame2Notify.payload) {            
                onGattSesame2Publish(itemCode: publishPayload.itemCode, data: publishPayload.payload)
            }
        }
        
        if sesame2Notify.opCode == .response {
            let responsePayload = Sesame2CmdResponsePayload(sesame2Notify.payload)
            onGattSesame2Response(responsePayload)
        }
    }
    
    private func onGattSesame2Response(_ payload: Sesame2CmdResponsePayload) {
//        L.d("🀄", "藍芽", "Res <==",payload.cmdItCode.plainName,payload.cmdOpCode.plainName,payload.cmdResultCode.plainName)
        onResponse?(payload)
        onResponse = nil
//        L.d("🀄", "藍芽", payload.cmdItCode.plainName, "semaphore 解鎖")
        
        semaphoreSesame?.signal()
    }
    
    private func onGattSesame2Publish(itemCode: SesameItemCode, data: Data) {
        switch itemCode {
        case .initalization:
            self.sesame2SessionToken = data
        case .mechSetting:
            if let sesame2setting = CHSesame2MechSettings.fromData(data) {
                mechSetting = sesame2setting
            }
        case .mechStatus:
            if let sesame2Status = Sesame2MechStatus.fromData(data) {
                if sesame2Status.retCode != 0 || sesame2Status.target == -32768 {
//                    L.d("sesame2Status.retCode", sesame2Status.retCode, "sesame2Status.target", sesame2Status.target)
//                    L.d("藍芽", "mechStatus 變化")
                    self.readHistoryCommand(){_ in}
                }
//                L.d("sesame2Status.isInLockRange", sesame2Status.isInLockRange, "sesame2Status.isInUnlockRange", sesame2Status.isInUnlockRange)
                mechStatus = sesame2Status
                self.deviceStatus = mechStatus!.isInLockRange  ? .locked() : mechStatus!.isInUnlockRange ? .unlocked() : .moved()
            }

        case .login:
            if let payload = Sesame2LoginResponsePayload.fromData(data) {
                self.mechStatus = payload.mechStatus
                self.mechSetting = payload.mechSetting
                self.fwVersion = payload.fwVersion
            }
        default:
            L.d("Ignore pub \(itemCode)")
        }
    }
}

extension CHSesame2Device {

    func sendCommand(_ payload:Sesame2Payload,
                     isCipher: SesameBleSegmentType = .ciphertext,
                     onResponse: Sesame2ResponseCallback? = nil) {
        commandQueue.async() {
//            L.d("🀄", "藍芽", payload.itemCode.plainName, "semaphore 排隊")
            self.semaphoreSesame?.wait()
            self.onResponse = onResponse
            if isCipher == .ciphertext {
                self.gattTxBuffer =  SesameBleTransmiter(.ciphertext, try! payload.toDataWithHeader(withCipher: self.cipher!))
            } else {
                self.gattTxBuffer = SesameBleTransmiter(.plaintext, payload.toDataWithHeader())
            }
//            L.d("🀄", "藍芽", "CMD==>", payload.itemCode.plainName, "semaphore 執行")
            self.transmit()
        }
    }

    func transmit() {
        if self.peripheral == nil {
            return
        }
        if self.characteristic == nil {
            return
        }

        if let data = gattTxBuffer?.getChunk() {
            //data[0] > 0x01 Android那边实际测试情况可能会出现is true。两端一致，因此要屏蔽以下判断代码，只保留withoutResponse.
            self.peripheral!.writeValue(data, for: self.characteristic!, type: .withoutResponse)
            transmit()
        }
    }
}
