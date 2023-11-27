//
//  CHWifiModule2Device+Peripheral.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

let WifiModule2Service = CBUUID(string: "1B7E8251-2877-41C3-B46E-CF057C562524")

enum WifiModule2Characteristics {
    static let write = CBUUID(string: "ACA0EF7C-EEAA-48AD-9508-19A6CEF6B356")
    static let notify = CBUUID(string: "8AC32D3f-5CB9-4D44-BEC2-EE689169F626")
}

extension CHWifiModule2Device {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == WifiModule2Service {
                peripheral.discoverCharacteristics([
                    WifiModule2Characteristics.write,
                    WifiModule2Characteristics.notify
                ], for: service)
            }
            
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            switch thisCharacteristic.uuid {
            case WifiModule2Characteristics.write:
                self.characteristic = characteristic
            case WifiModule2Characteristics.notify:
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            default:
                break
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let message = gattRxBuffer.feed(characteristic.value!) {
            if message.type == .ciphertext {
//                L.d("wm2收到加密")
                if let cipher = cipher {
                    let plaintext =  cipher.decrypt(message.buffer)
                    parseNotifyPayload(plaintext)
                } else {
                    L.d("Cipher not set")
                }
            } else if message.type == .plaintext {
                parseNotifyPayload(message.buffer)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        transmit()
    }
}
