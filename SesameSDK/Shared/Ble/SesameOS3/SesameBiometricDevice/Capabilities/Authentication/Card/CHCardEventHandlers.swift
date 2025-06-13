//
//  CHCardEventHandlers.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

class CHCardEventHandlers {
    
    public static func registerHandlers(for device: CHSesameBaseDevice) {
        // 卡片更改事件
        device.registerEventHandler(for: .SSM_OS3_CARD_CHANGE) { [weak device] _, data in
            guard let device = device else { return }
            let card = CHSesameTouchCard(data: data)
            device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
                delegate.onCardChanged(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
            }
        }
        
        // 卡片通知事件
        device.registerEventHandler(for: .SSM_OS3_CARD_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            processCardNotifyData(device: device, data: data)
        }
        
        // 卡片接收结束事件
        device.registerEventHandler(for: .SSM_OS3_CARD_LAST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
                delegate.onCardReceiveEnd(device: device)
            }
        }
        
        // 卡片接收开始事件
        device.registerEventHandler(for: .SSM_OS3_CARD_FIRST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
                delegate.onCardReceiveStart(device: device)
            }
        }
        
        // 模式变化事件
        device.registerEventHandler(for: .SSM_OS3_CARD_MODE_SET) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
                delegate.onCardModeChanged(mode: data.uint8)
            }
        }
        
        // 卡片删除事件
        device.registerEventHandler(for: .SSM_OS3_CARD_DELETE) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
                let payload = [UInt8](data)
                let cardIdLen = Int(payload[2])
                let cardIdData = data.subdata(in: 3..<(cardIdLen + 3))
                let cardId = cardIdData.toHexString()
                delegate.onCardDelete(device: device, id:cardId)
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
        device.notifyProtocolDelegates(CHCardDelegate.self) { delegate in
            delegate.onCardReceive(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
        }
    }
}
