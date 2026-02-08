//
//  CHFingerPrintHost.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/2/6.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

protocol CHFingerPrintHost: AnyObject, CHDevice, CHDeviceUtil, CHSesameConnector {
    func sendCommand(_ payload: SesameOS3Payload,
                     isCipher: SesameBleSegmentType,
                     onResponse: @escaping SesameOS3ResponseCallback)

    func registerEventHandler(for itemCode: SesameItemCode,
                              handler: @escaping (SesameItemCode, Data) -> Void)

    func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type)
    func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type)
    func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void)
}

extension CHSesameBaseDevice: CHFingerPrintHost {}
