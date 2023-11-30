//
//  CHSesameOS3.swift
//  SesameSDK
//  Created by tse on 2023/5/15.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

protocol CHSesameOS3Publish: AnyObject {
    func onGattSesamePublish(_ payload: SesameOS3PublishPayload)
}

class CHSesameOS3: CHBaseDevice ,CHSesameOS3Publish{
    func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        let itemCode = payload.itemCode
        let data = payload.payload
        
        if(itemCode == .initalization){
            self.mSesameToken = data
            if self.isRegistered {
                if isGuestKey {
                    (self as! CHDevice).sign(token: mSesameToken!.toHexString()) { signResult in
                        if case let .success(signedToken) = signResult {
                            (self as! CHDeviceUtil).login(token: signedToken.data)
                        }
                    }
                } else if deviceStatus == .waitingGatt() {
                    (self as! CHDeviceUtil).login(token: nil)
                }
            } else {
                deviceStatus = .readyToRegister()
            }
        }
    }

//    var delegateGatt: CHSesameOS3Publish?
    var mSesameToken: Data?
    var cipher: SesameOS3BleCipher?
    func transmit() {
        if self.peripheral == nil { return }
        if self.characteristic == nil { return }

        if let data = gattTxBuffer?.getChunk() {
            self.peripheral!.writeValue(data, for: self.characteristic!, type: .withoutResponse)
            transmit()
        }else{
            semaphoreSesame.signal()
        }
    }

    func sendCommand(_ payload:SesameOS3Payload,
                     isCipher: SesameBleSegmentType = .ciphertext,
                     onResponse: @escaping SesameOS3ResponseCallback) {
        
        let tmp = self.cmdCallBack[payload.itemCode]
        self.cmdCallBack[payload.itemCode] = onResponse
        if(tmp != nil){
            L.d("\(payload.itemCode.plainName) 隊列已經有了")
            return
        }
        commandQueue.async() {
            //            L.d("🀄", "藍芽", payload.itemCode.plainName, "semaphore 排隊")
            self.semaphoreSesame.wait()
            var message = payload.toDataWithHeader()
            if (isCipher == .ciphertext) {message = self.cipher!.encrypt(message)}
            self.gattTxBuffer = SesameBleTransmiter(isCipher, message)
            //            L.d("🀄", "CMD ==>", payload.itemCode.plainName, "semaphore 執行")
            self.transmit()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
                L.d("CHSesameTouchProDevice didDiscoverServices")
        for service in peripheral.services! {
            if(service.uuid.uuidString == "FD81"){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
                L.d("CHSesameTouchProDevice didDiscoverCharacteristicsFor")
        for characteristic in service.characteristics! {
            if characteristic.uuid ==  CBUUID(string: "16860002-A5AE-9856-B6D3-DBB4C676993E") {  self.characteristic = characteristic }
            if characteristic.properties.contains(.notify) {   peripheral.setNotifyValue(true, for: characteristic) }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            L.d("[ssm][say]: \(characteristic.value!.toHexLog())")
        if var mesg = gattRxBuffer.feed(characteristic.value!) {
            if mesg.type == .ciphertext { mesg.buffer = cipher!.decrypt(mesg.buffer) }
            parseNotifyPayload(mesg.buffer)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        transmit()
    }
    
    func parseNotifyPayload(_ data: Data) {
//                L.d("[ss5]: \(data.toHexLog())")
        let notify = Sesame2NotifyPayload(data: data)
        if notify.opCode == .publish {
            onGattSesamePublish(SesameOS3PublishPayload(data: notify.payload))
//            delegateGatt?.onGattSesamePublish(SesameOS3PublishPayload(data: notify.payload))
        }else if notify.opCode == .response {
            onGattSesameResponse(SesameOS3CmdResponsePayload(notify.payload))
        }
    }
    private func onGattSesameResponse(_ payload: SesameOS3CmdResponsePayload) {
        //        L.d("🀄","Res <==", payload.cmdItCode.plainName, payload.cmdResultCode.plainName)
        cmdCallBack[payload.cmdItCode]?(payload)
        cmdCallBack[payload.cmdItCode] = nil
        gattTxBuffer = nil
    }

//#if os(iOS)
//    deinit {
//        CHIoTManager.shared.unsubscribeCHDeviceShadow(self as! CHDevice)
//    }
//#endif

}
