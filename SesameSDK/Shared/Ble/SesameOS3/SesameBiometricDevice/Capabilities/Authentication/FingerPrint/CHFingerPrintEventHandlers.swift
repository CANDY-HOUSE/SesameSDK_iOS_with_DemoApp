//
//  CHFingerPrintEventHandlers.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation

class CHFingerPrintEventHandlers {
    public  static func registerHandlers(for device: CHSesameBaseDevice) {
        // 指纹更改事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_CHANGE) { [weak device] _, data in
            guard let device = device else { return }
            let card = CHSesameTouchCard(data: data)
            device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
                delegate.onFingerPrintChanged(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
            }
        }
        
        // 指纹通知事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            processCardNotifyData(device: device, data: data)
        }
        
        // 指纹接收结束事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_LAST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
                delegate.onFingerPrintReceiveEnd(device: device)
            }
        }
        
        // 指纹接收开始事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_FIRST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
                delegate.onFingerPrintReceiveStart(device: device)
            }
        }
        
        // 指纹变化事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_MODE_SET) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
                delegate.onFingerModeChange(mode: data.uint8)
            }
        }
        
        // 指纹删除事件
        device.registerEventHandler(for: .SSM_OS3_FINGERPRINT_DELETE) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
                let payload = [UInt8](data)
                delegate.onFingerPrintDelete(device: device, id:payload.toHexString())
            }
        }
    }
    
    // 处理卡片通知数据
    private static func processCardNotifyData(device: CHSesameBaseDevice, data: Data) {
        var cardDataSize = 0
        var cards = data.bytes
        
        repeat {
            cards = Array(cards.dropFirst(cardDataSize))
            if cards.isEmpty { break }
            
            let cardData = Data(cards)
            let card = CHSesameTouchCard(data: cardData)
            cardDataSize = Int(1 + 1 + card.idLength + 1 + card.nameLength)
            
            notifyCardReceived(device: device, card: card)
        } while (!cards.isEmpty)
    }
    
    // 通知卡片接收
    private static func notifyCardReceived(device: CHSesameBaseDevice, card: CHSesameTouchCard) {
        device.notifyProtocolDelegates(CHFingerPrintDelegate.self) { delegate in
            delegate.onFingerPrintReceive(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
        }
    }
}
