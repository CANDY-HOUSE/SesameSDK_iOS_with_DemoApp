//
//  CHSesameBiometricEventHost.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

protocol CHSesameBiometricEventHost: AnyObject {
    func registerEventHandler(for itemCode: SesameItemCode,
                              handler: @escaping (SesameItemCode, Data) -> Void)

    func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type)
    func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type)
    func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void)
}
