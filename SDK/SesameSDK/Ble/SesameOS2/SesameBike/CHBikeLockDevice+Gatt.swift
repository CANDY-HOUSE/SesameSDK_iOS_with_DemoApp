//
//  CHSesameBikeDevice+GattReceiver.swift
//  SesameSDK
//
//  Created by tse on 2023/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBikeDevice {

    func parseNotifyPayload(_ data: Data) {
        let notify = Sesame2NotifyPayload(data: data)
        if notify.opCode == .publish {
            let publishPayload = SesameOS3PublishPayload(data: notify.payload)
            onBikeLockGattPublish(itemCode: publishPayload.itemCode, data: publishPayload.payload)
        }
        
        if notify.opCode == .response {
            let responsePayload = Sesame2CmdResponsePayload(notify.payload)
            onGattResponse(responsePayload)
        }
    }
    
    private func onGattResponse(_ payload: Sesame2CmdResponsePayload) {
        onResponse?(payload)
        onResponse = nil
        semaphoreSesame?.signal()
//        L.d("🀄", "Bike", "CMD  <==", payload.cmdItCode)
    }
    
    private func onBikeLockGattPublish(itemCode: SesameItemCode, data: Data) {
        switch itemCode {
        case .initalization:
            self.bikeLockSessionToken = data
        case .mechSetting:
            if let setting = CHSesameBikeMechSettings.fromData(data) {
                mechSetting = setting
            }
        case .mechStatus:
            if let bikeLockStatus = BikeLockMechStatus.fromData(data) {

                mechStatus = bikeLockStatus
                self.deviceStatus = mechStatus!.isInLockRange ? .locked() : mechStatus!.isInUnlockRange ? .unlocked() : .moved()
            }

        case .login:
            if let payload = BikeLockLoginResponsePayload.fromData(data) {
                self.mechStatus = payload.mechStatus
                self.mechSetting = payload.mechSetting
                self.fwVersion = payload.fwVersion
            }
        default:
            L.d("Ignore pub \(itemCode)")
        }
    }
}
extension CHSesameBikeDevice {

    func sendCommand(_ payload:Sesame2Payload,
                     isCipher: SesameBleSegmentType = .ciphertext,
                     onResponse: Sesame2ResponseCallback? = nil) {

        commandQueue.async() {
//            L.d("🀄", "Bike", payload.itemCode.plainName, "semaphore 排隊")
            self.onResponse = onResponse
            self.semaphoreSesame?.wait()
            if isCipher == .ciphertext {
                self.gattTxBuffer =  SesameBleTransmiter(.ciphertext, try! payload.toDataWithHeader(withCipher: self.cipher!))
            } else {
                self.gattTxBuffer = SesameBleTransmiter(.plaintext, payload.toDataWithHeader())
            }
//            L.d("🀄", "Bike", "CMD==>", payload.itemCode.plainName, "semaphore 執行")
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
