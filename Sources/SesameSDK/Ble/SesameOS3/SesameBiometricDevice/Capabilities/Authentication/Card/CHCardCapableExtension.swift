//
//  CHCardCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
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
    
    func cardAdd(id: Data, name: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        
        let nameData = name.data(using: .utf8) ?? Data()
        
        sendCommand(.init(.SSM_OS3_CARD_ADD,
                          Data([0xF0, 0x00, UInt8(id.count)]) + id + Data(repeating: 0, count: max(0, 16-id.count)) +
                          Data([UInt8(nameData.count)]) + nameData + Data(repeating: 0, count: max(0, 16-nameData.count))
                         )) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func cardBatchAdd(data: Data, progressCallback: ((Int, Int) -> Void)?, result: @escaping (CHResult<CHEmpty>)) {
            if (!self.isBleAvailable(result)) { return }
            
            DispatchQueue.global().async {
                let dataSize = UInt16(data.count)
                var dataIndex: UInt16 = 0
                let MAX_PAYLOAD_SIZE = 209
                
                // 计算总包数
                let dataSizeInt = Int(dataSize)
                let maxPayloadInt = Int(MAX_PAYLOAD_SIZE)
                let totalPackets = (dataSizeInt + maxPayloadInt - 1) / maxPayloadInt
                var currentPacket = 0
                
                L.d("totalPackets: \(totalPackets), dataSize: \(dataSize)")
                
                while dataIndex < dataSize {
                    currentPacket += 1
                    
                    // 通知进度
                    DispatchQueue.main.async {
                        progressCallback?(currentPacket, totalPackets)
                    }
                    
                    var tempList = Data()
                    tempList.append(dataIndex.reversedBytes) // 需要反转字节序
                    tempList.append(dataSize.reversedBytes)  // 需要反转字节序
                    
                    let remainingSize = Int(dataSize - dataIndex)
                    let chunkSize = min(remainingSize, MAX_PAYLOAD_SIZE)
                    
                    let endIndex = Int(dataIndex) + chunkSize
                    tempList.append(data[Int(dataIndex)..<endIndex])
                    dataIndex += UInt16(chunkSize)
                    
                    L.d("Packet \(currentPacket)/\(totalPackets) - size: \(tempList.count)")
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    var sendSuccess = false
                    
                    self.sendCommand(.init(.STP_ITEM_CODE_CARDS_ADD, tempList)) { _ in
                        sendSuccess = true
                        semaphore.signal()
                    }
                    
                    semaphore.wait()
                    
                    if !sendSuccess {
                        result(.failure(NSError(domain: "CardBatchAdd", code: -1,
                                              userInfo: [NSLocalizedDescriptionKey: "Failed at packet \(currentPacket)"])))
                        return
                    }
                    
                    // 如果还有数据要发送，延迟4秒
                    if dataIndex < dataSize {
                        Thread.sleep(forTimeInterval: 4.0)
                    }
                }
                
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }
}
