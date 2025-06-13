//
//  CHPassCodeEventHandlers.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation

class CHPassCodeEventHandlers {
    public  static func registerHandlers(for device: CHSesameBaseDevice) {
        // 密码更改事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_CHANGE) { [weak device] _, data in
            guard let device = device else { return }
            let card = CHSesameTouchCard(data: data)
            device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
                delegate.onPassCodeChanged(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
            }
        }
        
        // 密码通知事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            processCardNotifyData(device: device, data: data)
        }
        
        // 密码接收结束事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_LAST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
                delegate.onPassCodeReceiveEnd(device: device)
            }
        }
        
        // 密码接收开始事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_FIRST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
                delegate.onPassCodeReceiveStart(device: device)
            }
        }
        
        // 模式变化事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_MODE_SET) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
                delegate.onPassCodeModeChanged(mode: data.uint8)
            }
        }
        
        // 密码删除事件
        device.registerEventHandler(for: .SSM_OS3_PASSCODE_DELETE) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
                let payload = [UInt8](data)
                let passCodeIdLen = Int(payload[2])
                let passCodeIdData = data.subdata(in: 3..<(passCodeIdLen + 3))
                let passCodeId = passCodeIdData.toHexString()
                delegate.onPassCodeDelete(device: device, id:passCodeId)
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
        device.notifyProtocolDelegates(CHPassCodeDelegate.self) { delegate in
            delegate.onPassCodeReceive(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
        }
    }
}
