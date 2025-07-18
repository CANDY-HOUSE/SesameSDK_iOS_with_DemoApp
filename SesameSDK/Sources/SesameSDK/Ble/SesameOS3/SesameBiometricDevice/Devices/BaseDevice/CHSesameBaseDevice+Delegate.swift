//
//  CHSesameBaseDevice+ Delegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension CHSesameBaseDevice {
    
    public func registerDelegate<T: AnyObject>(_ delegate: T, for type: T.Type) {
        delegateManager.register(delegate, for: type)
    }
    
    public func unregisterDelegate<T: AnyObject>(_ delegate: T, for type: T.Type) {
        delegateManager.unregister(delegate, for: type)
    }
    
    public func notifyDelegates<T: AnyObject>(_ type: T.Type, handler: (T) -> Void) {
        delegateManager.notify(type, handler: handler)
    }
    
    public func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        delegateManager.register(delegate, for: type)
    }
    
    public func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        delegateManager.unregister(delegate, for: type)
    }
    
    public func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void) {
        delegateManager.notify(type, handler: handler)
    }
}
