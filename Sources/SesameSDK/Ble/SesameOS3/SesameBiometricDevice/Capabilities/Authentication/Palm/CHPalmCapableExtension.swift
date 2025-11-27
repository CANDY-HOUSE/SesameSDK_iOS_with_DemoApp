//
//  CHPalmCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHPalmCapable where Self: CHSesameBaseDevice{
    
    func palms(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_PALM_GET)) { _ in
            L.d("SSM_OS3_PASSCODE_GET ok")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func palmDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_PALM_DELETE,ID.hexStringtoData())) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func palmModeGet(result: @escaping (CHResult<UInt8>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.SSM_OS3_PALM_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }
    
    func palmModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.SSM_OS3_PALM_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func registerEventDelegate(_ delegate: CHPalmDelegate) {
        CHPalmEventHandlers.registerHandlers(for: self)
        registerProtocolDelegate(delegate, for: CHPalmDelegate.self)
    }
    
    func unregisterEventDelegate(_ delegate: CHPalmDelegate) {
        unregisterProtocolDelegate(delegate, for: CHPalmDelegate.self)
    }
    
}
