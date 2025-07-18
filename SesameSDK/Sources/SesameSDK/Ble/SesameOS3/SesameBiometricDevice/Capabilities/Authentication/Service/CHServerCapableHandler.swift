//
//  CHServer.swift
//  SesameSDK
//
//  Created by eddy on 2025/5/27.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
public struct BiometricDataWrapper: Codable {
    public let op: String
    public let deviceID: String
    public let items: [BiometricData]
    public init(op: String, deviceID: String, items: [BiometricData]) {
        self.op = op
        self.deviceID = deviceID
        self.items = items
    }
}

public struct BiometricDeleteWrapper: Codable {
    let type: Int8
    let nameUUID: String
    let subUUID: String
    let deviceUUID: String
    let name: String
    let id: String
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
        case type = "cardType"
        case nameUUID = "cardNameUUID"
        case subUUID
        case deviceUUID = "stpDeviceUUID"
        case name
        case id = "cardID"
        case timestamp
    }
    
    init(type: Int8, nameUUID: String, subUUID: String, deviceUUID: String, name: String, id: String) {
        self.type = type
        self.nameUUID = nameUUID
        self.subUUID = subUUID
        self.deviceUUID = deviceUUID
        self.name = name
        self.id = id
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    }
}

public struct BiometricData: Codable {
    public let credentialId: String
    public var nameUUID: String
    public let type: String
    public let name: String
    public init(credentialId: String, nameUUID: String, type: String, name: String) {
        self.credentialId = credentialId
        self.nameUUID = nameUUID
        self.type = type
        self.name = name
    }
    
    static func toBiometricDatas(_ ary: [[String: Any]]) -> [BiometricData] {
        return ary.map { dict in
            guard let credentialId = dict["credentialId"] as? String else {
                return BiometricData(credentialId: "", nameUUID: "", type: "", name: "")
            }
            guard let nameUUID = dict["nameUUID"] as? String else {
                return BiometricData(credentialId: "", nameUUID: "", type: "", name: "")
            }
            guard let type = dict["type"] as? String else {
                return BiometricData(credentialId: "", nameUUID: "", type: "", name: "")
            }
            guard let name = dict["name"] as? String else {
                return BiometricData(credentialId: "", nameUUID: "", type: "", name: "")
            }
            return BiometricData(credentialId: credentialId, nameUUID: nameUUID, type: type, name: name)
        }
    }
    
    public static func isUUIDv4(name: String?) -> Bool {
        guard var name = name else { return false }
        name = name.replacingOccurrences(of: "-", with: "")
        var byteArray = [UInt8]()
        var index = name.startIndex
        while index < name.endIndex {
            let nextIndex = name.index(index, offsetBy: 2, limitedBy: name.endIndex) ?? name.endIndex
            let hexByte = name[index..<nextIndex]
            
            if let value = UInt8(String(hexByte), radix: 16) {
                byteArray.append(value)
            } else {
                return false // 无效的十六进制字符
            }
            
            index = nextIndex
        }
        // UUIDv4 的固定长度为 16 字节
        if byteArray.count != 16 { return false }
        let uuidVersionByte: UInt8 = 0x40 // UUIDv4 版本号
        let uuidVariantByte: UInt8 = 0x80 // UUIDv4 变体
        return (byteArray[6] & 0xF0 == uuidVersionByte) && (byteArray[8] & 0xC0 == uuidVariantByte)
    }
}

public protocol CHServerCapableHandler {
    func postAuthenticationData(_ data: BiometricDataWrapper, result: @escaping(CHResult<[BiometricData]>))
    func putAuthenticationData(_ data: BiometricDataWrapper, result: @escaping(CHResult<CHEmpty>))
    func deleteAuthenticationData(_ data: BiometricDataWrapper, result: @escaping(CHResult<CHEmpty>))
}

extension CHServerCapableHandler {
    func postAuthenticationData(_ data: BiometricDataWrapper, result: @escaping(CHResult<[BiometricData]>)) {
        let tempData = BiometricDataWrapper(op: data.op + "_post", deviceID: data.deviceID, items: data.items)
        let payload = try! JSONEncoder().encode(tempData)
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/credential", payload)) { resposne in
            switch resposne {
            case .success(let data):
                if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any],
                   let itemsDict = jsonObj["data"] as? [String: Any],
                    let itemArys = itemsDict["items"] as? [[String: Any]] {
                    let items = BiometricData.toBiometricDatas(itemArys)
                    result(.success(.init(input: items)))
                } else {
                    result(.failure(NSError.parseError))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func putAuthenticationData(_ data: BiometricDataWrapper, result  : @escaping(CHResult<CHEmpty>)) {
        let tempData = BiometricDataWrapper(op: data.op + "_put", deviceID: data.deviceID, items: data.items)
        let payload = try! JSONEncoder().encode(tempData)
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/credential", payload)) { resposne in
            switch resposne {
            case .success(let data):
                L.d("get success data: \(String(data: data!, encoding: .utf8) ?? "No data")")
//                let codes = try! JSONDecoder().decode([BiometricData].self, from: data!)
                result(.success(.init(input: CHEmpty())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func deleteAuthenticationData(_ data: BiometricDataWrapper, result  : @escaping(CHResult<CHEmpty>)) {
        let tempData = BiometricDataWrapper(op: data.op + "_delete", deviceID: data.deviceID, items: data.items)
        let payload = try! JSONEncoder().encode(tempData)
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/credential", payload)) { resposne in
            switch resposne {
            case .success(_):
                result(.success(.init(input: CHEmpty())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}
