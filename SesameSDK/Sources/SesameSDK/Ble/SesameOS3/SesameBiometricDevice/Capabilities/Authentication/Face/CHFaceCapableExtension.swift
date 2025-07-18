//
//  CHFaceCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHFaceCapable where Self: CHSesameBaseDevice {
    
    func faces(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FACE_GET)) { _ in
            L.d("SSM_OS3_PASSCODE_GET ok")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func faceDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FACE_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func faceModeGet(result: @escaping (CHResult<UInt8>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FACE_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }
    
    func faceModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FACE_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func faceNameSet(faceNameRequest: CHFaceNameRequest, result: @escaping(CHResult<String>)) {
        let payload = try! JSONEncoder().encode(faceNameRequest)
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/face/name", payload)) { resposne in
            switch resposne {
            case .success(let data):
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    result(.success(.init(input: responseString)))
                } else {
                    result(.success(.init(input: "")))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func registerEventDelegate(_ delegate: CHFaceDelegate) {
        CHFaceEventHandlers.registerHandlers(for: self)
        registerProtocolDelegate(delegate, for: CHFaceDelegate.self)
    }
    
    func unregisterEventDelegate(_ delegate: CHFaceDelegate) {
        unregisterProtocolDelegate(delegate, for: CHFaceDelegate.self)
    }
    
}
