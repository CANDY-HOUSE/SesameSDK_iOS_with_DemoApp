//
//  CHFaceEventHandlers.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation

class CHFaceEventHandlers {
    public  static func registerHandlers(for device: CHSesameBaseDevice) {
        // Face更改事件
        device.registerEventHandler(for: .SSM_OS3_FACE_CHANGE) { [weak device] _, data in
            guard let device = device else { return }
            let card = CHSesameTouchCard(data: data)
            device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
                delegate.onFaceChanged(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
            }
        }
        
        // Face通知事件
        device.registerEventHandler(for: .SSM_OS3_FACE_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            processCardNotifyData(device: device, data: data)
        }
        
        // Face接收结束事件
        device.registerEventHandler(for: .SSM_OS3_FACE_LAST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
                delegate.onFaceReceiveEnd(device: device)
            }
        }
        
        // Face接收开始事件
        device.registerEventHandler(for: .SSM_OS3_FACE_FIRST) { [weak device] _, _ in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
                delegate.onFaceReceiveStart(device: device)
            }
        }
        
        // 模式变化事件
        device.registerEventHandler(for: .SSM_OS3_FACE_MODE_SET) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
                delegate.onFaceModeChanged(mode: data.uint8)
            }
        }
        
        device.registerEventHandler(for: .SSM_OS3_FACE_MODE_DELETE_NOTIFY) { [weak device] _, data in
            guard let device = device else { return }
            device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
                if(data.count>=2) {
                    let faceId = data[0]
                    let isSuccess = data[1] == 0
                    delegate.onFaceDeleted(faceId: faceId,isSuccess:isSuccess)
                }
            }
        }
    }
    
    // 处理Face通知数据
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
        device.notifyProtocolDelegates(CHFaceDelegate.self) { delegate in
            delegate.onFaceReceive(device: device, id: card.cardID, name: card.cardName, type: card.cardType)
        }
    }
}
