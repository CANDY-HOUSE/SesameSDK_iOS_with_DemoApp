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

    public func ecdh(remotePublicKey: [UInt8]) -> [UInt8] {
        var error: Unmanaged<CFError>?

        let secpubKey = SecKeyCreateWithData(Data(hex: "04") + Data(remotePublicKey) as CFData, [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32

            ] as CFDictionary, nil)

        let rollBackKey = SecKeyCreateWithData(ecckeydata as CFData, [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            ] as CFDictionary, nil)


        let keyPairAttr: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32,
            kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: false],
            kSecPublicKeyAttrs as String:[kSecAttrIsPermanent as String: false],
        ]


        if(rollBackKey == nil){
//            CandyhouseKeychainManager.shared.keychain.clear()
            return "0000000000000000000000000000".bytes
        }
        // todo tse  secpubKey!   在鑰匙錯誤下。解包異常。
        let shared1 = SecKeyCopyKeyExchangeResult(rollBackKey!,
                                                  SecKeyAlgorithm.ecdhKeyExchangeStandard,
                                                  secpubKey!,
                                                  keyPairAttr as CFDictionary,
                                                  &error)

        let bytes = [UInt8](shared1! as Data)

        return bytes

    }
    
    public func havePubKey(remotePublicKey: [UInt8]) -> Bool {
        return SecKeyCreateWithData(Data(hex: "04") + Data(remotePublicKey) as CFData, [
                kSecAttrKeyType as String: kSecAttrKeyTypeEC,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                SecKeyKeyExchangeParameter.requestedSize.rawValue as String: 32
            ] as CFDictionary, nil) != nil
    }
}


