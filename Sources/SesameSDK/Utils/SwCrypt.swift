//
//  SwCrypt.swift
//  SesameSDK
//
//  Created by tse on 2020/8/22.
//  from https://github.com/soyersoyer/SwCrypt
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
class SwKeyStore {
    
    enum SecError: OSStatus, Error {
        case unimplemented = -4
        case param = -50
        case allocate = -108
        case notAvailable = -25291
        case authFailed = -25293
        case duplicateItem = -25299
        case itemNotFound = -25300
        case interactionNotAllowed = -25308
        case decode = -26275
        case missingEntitlement = -34018
        
        static var debugLevel = 1
        
        init(_ status: OSStatus, function: String = #function, file: String = #file, line: Int = #line) {
            self = SecError(rawValue: status)!
            if SecError.debugLevel > 0 {
                L.e("\(self._domain): \(self) (\(self.rawValue))", file: file, function: function, line: line)
            }
        }
        init(_ type: SecError, function: String = #function, file: String = #file, line: Int = #line) {
            self = type
            if SecError.debugLevel > 0 {
                L.e("\(self._domain): \(self) (\(self.rawValue))", file: file, function: function, line: line)
            }
        }
    }
    
    static func upsertKey(_ pemKey: String, keyTag: String,
                                 options: [NSString : AnyObject] = [:]) throws {
        let pemKeyAsData = pemKey.data(using: String.Encoding.utf8)!
        
        var parameters: [NSString : AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrIsPermanent: true as AnyObject,
            kSecAttrApplicationTag: keyTag as AnyObject,
            kSecValueData: pemKeyAsData as AnyObject
        ]
        options.forEach { k, v in
            parameters[k] = v
        }
        
        var status = SecItemAdd(parameters as CFDictionary, nil)
        if status == errSecDuplicateItem {
            try delKey(keyTag)
            status = SecItemAdd(parameters as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw SecError(status) }
    }
    
    static func getKey(_ keyTag: String) throws -> String {
        let parameters: [NSString : AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrKeyType : kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag : keyTag as AnyObject,
            kSecReturnData : true as AnyObject
        ]
        var data: AnyObject?
        let status = SecItemCopyMatching(parameters as CFDictionary, &data)
        guard status == errSecSuccess else { throw SecError(status) }
        
        guard let pemKeyAsData = data as? Data else {
            throw SecError(.decode)
        }
        guard let result = String(data: pemKeyAsData, encoding: String.Encoding.utf8) else {
            throw SecError(.decode)
        }
        return result
    }
    
    static func delKey(_ keyTag: String) throws {
        let parameters: [NSString : AnyObject] = [
            kSecClass : kSecClassKey,
            kSecAttrApplicationTag: keyTag as AnyObject
        ]
        let status = SecItemDelete(parameters as CFDictionary)
        guard status == errSecSuccess else { throw SecError(status) }
    }
}

class CC {
    fileprivate static let dl = dlopen("/usr/lib/system/libcommonCrypto.dylib", RTLD_NOW)

    class CMAC {
        static func AESCMACWithTime(_ key: Data) -> Data {
            var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
            let timestampData = Data(bytes: &timestamp,
                                     count: MemoryLayout.size(ofValue: timestamp))
            
            let randomTag = Data(timestampData.arrayOfBytes()[1...3])
            let keyCheck = CC.CMAC.AESCMAC(randomTag,
                                           key: key)
            return keyCheck
        }
        
        static func AESCMAC(_ data: Data, key: Data) -> Data {
            var result = Data(count: 16)
            withUnsafePointers(key, data, &result, { keyBytes, dataBytes, resultBytes in
                CCAESCmac!(keyBytes,
                           dataBytes, data.count,
                           resultBytes)
            })
            return result
        }
        
        static func available() -> Bool {
            return CCAESCmac != nil
        }
        
        fileprivate typealias CCAESCmacT = @convention(c) (
            _ key: UnsafeRawPointer,
            _ data: UnsafeRawPointer, _ dataLen: size_t,
            _ macOut: UnsafeMutableRawPointer) -> Void
        fileprivate static let CCAESCmac: CCAESCmacT? = getFunc(dl!, f: "CCAESCmac")
    }
}

private func getFunc<T>(_ from: UnsafeMutableRawPointer, f: String) -> T? {
    let sym = dlsym(from, f)
    guard sym != nil else {
        return nil
    }
    return unsafeBitCast(sym, to: T.self)
}

extension Data {
    func arrayOfBytes() -> [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        self.copyBytes(to: &bytesArray, count: count * MemoryLayout<UInt8>.size)
        return bytesArray
    }
}

fileprivate func withUnsafePointers<A0, A1, A2, Result>(
    _ arg0: Data,
    _ arg1: Data,
    _ arg2: inout Data,
    _ body: (
        UnsafePointer<A0>,
        UnsafePointer<A1>,
        UnsafeMutablePointer<A2>) throws -> Result
) rethrows -> Result {
    return try arg0.withUnsafeBytes { p0 in
        return try arg1.withUnsafeBytes { p1 in
            return try arg2.withUnsafeMutableBytes { p2 in
                return try body(p0, p1, p2)
            }
        }
    }
}
