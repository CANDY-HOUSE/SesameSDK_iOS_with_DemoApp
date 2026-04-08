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
    private let fpDelegateManager = CHDelegateManager()
    
    var sesame2Keys: [String: String] { [:] }
    
    func registerEventHandler(for itemCode: SesameItemCode,
                              handler: @escaping (SesameItemCode, Data) -> Void) {
        fpEventHandlers[itemCode] = handler
    }
    
    func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        fpDelegateManager.register(delegate, for: type)
    }
    
    func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        fpDelegateManager.unregister(delegate, for: type)
    }
    
    func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void) {
        fpDelegateManager.notify(type, handler: handler)
    }
    
    override func handleLockDevicePublish(_ payload: SesameOS3PublishPayload) {
        super.handleLockDevicePublish(payload)
        
        if let handler = fpEventHandlers[payload.itemCode] {
            handler(payload.itemCode, payload.payload)
        }
    }
}
