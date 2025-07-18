//
//  CHPalmEventHandlers.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation

class CHPalmEventHandlers {
    public  static func registerHandlers(for device: CHSesameBaseDevice) {
        device.registerEventHandler(for: .SSM_OS3_PALM_CHANGE) { [weak device] _, data in
            guard let device = device else { return }
            let card = CHSesameTouchCard(data: data)
            device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
                delegate.onPalmChanged(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
            }
        }
    
        device.registerEventHandler(for: .SSM_OS3_PALM_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            processCardNotifyData(device: device, data: data)
        }

        device.registerEventHandler(for: .SSM_OS3_PALM_LAST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
                delegate.onPalmReceiveEnd(device: device)
            }
        }
        
        device.registerEventHandler(for: .SSM_OS3_PALM_FIRST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
                delegate.onPalmReceiveStart(device: device)
            }
        }
        
        // 模式变化事件
        device.registerEventHandler(for: .SSM_OS3_PALM_MODE_SET) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
                delegate.onPalmModeChanged(mode: data.uint8)
            }
        }
        
        device.registerEventHandler(for: .SSM_OS3_PALM_MODE_DELETE_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
                if(data.count>=2) {
                    let palmId = data[0]
                    let isSuccess = data[1] == 0
                    delegate.onPalmDeleted(palmId: palmId, isSuccess:isSuccess)
                }
            }
        }
    }

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
    
    private static func notifyCardReceived(device: CHSesameBaseDevice, card: CHSesameTouchCard) {
        device.notifyProtocolDelegates(CHPalmDelegate.self) { delegate in
            delegate.onPalmReceive(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
        }
    }
}
