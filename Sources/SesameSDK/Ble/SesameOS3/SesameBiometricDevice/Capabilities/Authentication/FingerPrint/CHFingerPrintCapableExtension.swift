//
//  CHFingerPrintCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
extension CHFingerPrintCapable where Self: CHSesameBaseDevice {
    func fingerPrints( result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.SSM_OS3_FINGERPRINT_GET)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func fingerPrintDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.SSM_OS3_FINGERPRINT_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func fingerPrintsChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>) ) { //改名稱
        if (!self.isBleAvailable(result)) { return }
        
        let idData = ID.hexStringtoData()
        L.d("idData???=>", idData)
        let payload = Data([UInt8(idData.count)]) + idData + name.hexStringtoData()
        L.d("TouchDevice payload =>",payload.toHexLog())
        sendCommand(.init(.SSM_OS3_FINGERPRINT_CHANGE, payload)) { _ in
            L.d("[TouchDevice][fingerPrintsChange][ok]")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func fingerPrintModeGet(result: @escaping (CHResult<UInt8>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FINGERPRINT_MODE_GET)) { response in
            L.d("[TouchDevice][fingerPrintModeGet]",response.data[0])
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }
    
    func fingerPrintModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        sendCommand(.init(.SSM_OS3_FINGERPRINT_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    func fingerPrintNameSet(fingerPrintNameRequest: CHFingerPrintNameRequest,result: @escaping(CHResult<String>)) {
        let payload = try! JSONEncoder().encode(fingerPrintNameRequest)
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/fingerprint/name", payload)) { resposne in
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
    
    func registerEventDelegate(_ delegate: CHFingerPrintDelegate) {
        CHFingerPrintEventHandlers.registerHandlers(for: self)
        registerProtocolDelegate(delegate, for: CHFingerPrintDelegate.self)
    }
    
    func unregisterEventDelegate(_ delegate: CHFingerPrintDelegate) {
        unregisterProtocolDelegate(delegate, for: CHFingerPrintDelegate.self)
    }
    
}
