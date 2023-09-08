//
//  CHSwitchDevice+GattReceiver.swift
//  SesameSDK
//
//  Created by tse on 2023/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBotDevice {

    func parseNotifyPayload(_ data: Data) {
        let sesameBotNotify = Sesame2NotifyPayload(data: data)
        if sesameBotNotify.opCode == .publish {
            let publishPayload = SesameOS3PublishPayload(data: sesameBotNotify.payload)
            onGattSesameBotPublish(itemCode: publishPayload.itemCode, data: publishPayload.payload)
        }
        
        if sesameBotNotify.opCode == .response {
            let responsePayload = Sesame2CmdResponsePayload(sesameBotNotify.payload)
            onGattSwitchResponse(responsePayload)
        }
    }
    
    private func onGattSwitchResponse(_ payload: Sesame2CmdResponsePayload) {
        onResponse?(payload)
        onResponse = nil

//        L.d("🀄", "藍芽", payload.cmdItCode.plainName, "semaphore 解鎖")
        semaphoreSesame?.signal()
    }
    
    private func onGattSesameBotPublish(itemCode: SesameItemCode, data: Data) {
        switch itemCode {
        case .initalization:
            self.sesameBotSessionToken = data
        case .mechSetting:
            if let switchSetting = CHSesameBotMechSettings.fromData(data) {
                mechSetting = switchSetting
            }
        case .mechStatus:
            if let switchStatus = SesameBotMechStatus.fromData(data) {
                if(switchStatus.retCode != 0){
                     self.readHistoryCommand(){_ in}
                }
                mechStatus = switchStatus
                self.deviceStatus = mechStatus!.isInLockRange ? .locked() : mechStatus!.isInUnlockRange ? .unlocked() : .moved()
            }
        case .login:
            if let payload = SesameBotLoginResponsePayload.fromData(data) {
                self.mechStatus = payload.mechStatus
                self.mechSetting = payload.mechSetting
                self.fwVersion = payload.fwVersion
            }
        default:
            L.d("Ignore pub \(itemCode)")
        }
    }
}

extension CHSesameBotDevice {
    func sendCommand(_ payload:Sesame2Payload,
                     isCipher: SesameBleSegmentType = .ciphertext,
                     onResponse: Sesame2ResponseCallback? = nil) {

        commandQueue.async() {
//            L.d("🀄", "藍芽", payload.itemCode.plainName, "semaphore 排隊")
            self.onResponse = onResponse
            self.semaphoreSesame?.wait()
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
            if data[0] > 0x01 {
                self.peripheral!.writeValue(data, for: self.characteristic!, type: .withResponse)
            } else {
                self.peripheral!.writeValue(data, for: self.characteristic!, type: .withoutResponse)
                transmit()
            }
        }
    }
}
