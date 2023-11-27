//
//  CHSesameBikeDevice+Peripheral.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

private let uuidChr02 = CBUUID(string: "16860002-A5AE-9856-B6D3-DBB4C676993E")

extension CHSesameBikeDevice {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid ==  uuidChr02 {
                self.characteristic = characteristic
            }

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let mesg = gattRxBuffer.feed(characteristic.value!) {
            if mesg.type == .ciphertext {
                if let cipher = cipher {
                    do {
                        let plaintext = try cipher.decrypt(mesg.buffer)
                        parseNotifyPayload(plaintext)
                    } catch {
                        L.d("解密錯誤 ！！！", error)
                    }
                }
            } else if mesg.type == .plaintext {
                parseNotifyPayload(mesg.buffer)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        transmit()
    }
}
