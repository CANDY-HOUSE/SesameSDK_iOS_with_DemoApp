//
//  CHSesameBike3Device.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/2/6.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

final class CHSesameBike3Device: CHSesameBike2Device, CHFingerPrintCapable, CHFingerPrintHost {
    
    private var fpEventHandlers: [SesameItemCode: (SesameItemCode, Data) -> Void] = [:]
    
    private let fpDelegates = NSHashTable<AnyObject>.weakObjects()
    
    var sesame2Keys: [String : String] { [:] }
    
    func registerEventHandler(for itemCode: SesameItemCode,
                              handler: @escaping (SesameItemCode, Data) -> Void) {
        fpEventHandlers[itemCode] = handler
    }
    
    func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        guard type == CHFingerPrintDelegate.self else { return }
        fpDelegates.add(delegate)
    }
    
    func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        guard type == CHFingerPrintDelegate.self else { return }
        fpDelegates.remove(delegate)
    }
    
    func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void) {
        guard type == CHFingerPrintDelegate.self else { return }
        for obj in fpDelegates.allObjects {
            if let d = obj as? T {
                handler(d)
            }
        }
    }
    
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        
        // 将指纹相关 itemCode 的 publish 转给指纹 handlers
        if let handler = fpEventHandlers[payload.itemCode] {
            handler(payload.itemCode, payload.payload)
        }
    }
}
