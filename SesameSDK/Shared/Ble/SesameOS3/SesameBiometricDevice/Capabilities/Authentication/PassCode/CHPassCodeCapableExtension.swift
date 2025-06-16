//
//  CHPassCodeCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension CHPassCodeCapable where Self: CHSesameBaseDevice {
    
    func passCodes(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_GET)) { _ in
            L.d("SSM_OS3_PASSCODE_GET ok")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        let idData = ID.hexStringtoData()
        let payload = Data([UInt8(idData.count)]) + idData + name.hexStringtoData()
        sendCommand(.init(.SSM_OS3_PASSCODE_CHANGE, payload)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeModeGet(result: @escaping (CHResult<UInt8>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }

    func passCodeModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func passCodeNameSet(passCodeNameRequest: CHKeyBoardPassCodeNameRequest, result: @escaping(CHResult<String>)) {
        let payload = try! JSONEncoder().encode(passCodeNameRequest)
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/passcode/name", payload)) { resposne in
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
    
    func registerEventDelegate(_ delegate: CHPassCodeDelegate) {
        CHPassCodeEventHandlers.registerHandlers(for: self)
        registerProtocolDelegate(delegate, for: CHPassCodeDelegate.self)
    }
    
    func unregisterEventDelegate(_ delegate: CHPassCodeDelegate) {
        unregisterProtocolDelegate(delegate, for: CHPassCodeDelegate.self)
    }
    
}
