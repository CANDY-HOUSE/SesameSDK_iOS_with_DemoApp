//
//  CHCardCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension CHCardCapable where Self: CHSesameBaseDevice {
    func cards(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_GET)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardsChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        let idData = ID.hexStringtoData()
        let payload = Data([UInt8(idData.count)]) + idData + name.hexStringtoData()
        L.d("TouchDevice",payload.toHexLog())
        sendCommand(.init(.SSM_OS3_CARD_CHANGE, payload)) { _ in
            L.d("[TouchDevice][fingerPrintsChange][ok]")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardsModeGet(result: @escaping (CHResult<UInt8>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }

    func cardsModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func cardNameSet(cardNameRequest: CHCardNameRequest, result: @escaping(CHResult<String>)) {
        let payload = try! JSONEncoder().encode(cardNameRequest)
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/card/name", payload)) { resposne in
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
    
    func registerEventDelegate(_ delegate: CHCardDelegate) {
        CHCardEventHandlers.registerHandlers(for: self)
        registerProtocolDelegate(delegate, for: CHCardDelegate.self)
    }
    
    func unregisterEventDelegate(_ delegate: CHCardDelegate) {
        unregisterProtocolDelegate(delegate, for: CHCardDelegate.self)
    }
    
}
