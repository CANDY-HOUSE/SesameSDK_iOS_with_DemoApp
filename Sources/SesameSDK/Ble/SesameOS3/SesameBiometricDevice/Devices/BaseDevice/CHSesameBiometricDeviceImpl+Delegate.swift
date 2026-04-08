//
//  CHSesameBiometricDeviceImpl+Delegate.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBiometricDeviceImpl {

    public func registerDelegate<T: AnyObject>(_ delegate: T, for type: T.Type) {
        delegateManager.register(delegate, for: type)
    }

    public func unregisterDelegate<T: AnyObject>(_ delegate: T, for type: T.Type) {
        delegateManager.unregister(delegate, for: type)
    }

    public func notifyDelegates<T: AnyObject>(_ type: T.Type, handler: (T) -> Void) {
        delegateManager.notify(type, handler: handler)
    }
}
