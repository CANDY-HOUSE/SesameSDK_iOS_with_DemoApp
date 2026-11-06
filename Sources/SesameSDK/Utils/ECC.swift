//
//  ECC.swift
//  sesame2-sdk
//
//  Created by Tse on 2020/04/20.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
class ECC {
    static func generate() -> ECC {
        autoreleasepool {
            var publicKeySec, privateKeySec: SecKey?
            let keyattribute = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String : 256
            ] as [String : Any] as CFDictionary
            SecKeyGeneratePair(keyattribute, &publicKeySec, &privateKeySec)
            var error: Unmanaged<CFError>?
            let keyData = SecKeyCopyExternalRepresentation(privateKeySec!, &error)
            let data = keyData! as Data
            return ECC(ecckeydata: data)
        }
    }

    internal var privateKey: [UInt8]
    internal var publicKey: [UInt8]
    internal var ecckeydata :Data
    init(ecckeydata: Data) {

        self.ecckeydata = ecckeydata
        var privateKeyBytes = ecckeydata.bytes
        //        L.d("privateKeyBytes!!",privateKeyBytes)
        privateKeyBytes.removeFirst()
        let pointSize = privateKeyBytes.count / 3
        let xBytes = privateKeyBytes[0..<pointSize]
        let yBytes = privateKeyBytes[pointSize..<pointSize*2]
        let dBytes = privateKeyBytes[pointSize*2..<pointSize*3]
        //        L.d("pub",Data(xBytes+yBytes),xBytes+yBytes)
        //        L.d("pri",Data(dBytes),dBytes)
        self.privateKey  = Array(dBytes)
        self.publicKey = Array(xBytes+yBytes)

    }

    enum ECDHError: Error {
        case invalidKey, exchangeFailed
    }

    func ecdh(remotePublicKey: [UInt8]) throws -> [UInt8] {
        guard let remoteKey = SecKeyCreateWithData(Data(hex: "04") + Data(remotePublicKey) as CFData, [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ] as CFDictionary, nil),
              let privateKey = SecKeyCreateWithData(ecckeydata as CFData, [
                kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
              ] as CFDictionary, nil) else {
            throw ECDHError.invalidKey
        }
        let parameters = [SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let shared = SecKeyCopyKeyExchangeResult(privateKey, .ecdhKeyExchangeStandard, remoteKey, parameters, &error) as Data?,
              shared.count >= 16 else {
            throw ECDHError.exchangeFailed
        }
        return [UInt8](shared)
    }

    public func havePubKey(remotePublicKey: [UInt8]) -> Bool {
        return SecKeyCreateWithData(Data(hex: "04") + Data(remotePublicKey) as CFData, [
                kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32
            ] as CFDictionary, nil) != nil
    }
}


