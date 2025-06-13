//
//  Sesame2BleCipher.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/08/24.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

class Sesame2BleCipher {
    var encryptCounter: UInt64
    var decryptCounter: UInt64
    var name: String
    var sessionKey: [UInt8]
    var sessionToken: Data

    init(name:String, sessionKey: Data, sessionToken: Data) {
        self.sessionKey = sessionKey.bytes
        self.sessionToken = sessionToken
        self.name = name
        self.encryptCounter = 0
        self.decryptCounter = 0
    }

    public func encrypt(_ plaintext: Data) throws -> Data {
//        L.d("🤡===>", encryptCounter, Thread.current)
        let nonce = encryptCounter.toEncryCounter() + sessionToken
        let ret = try AES.CCM.encrypt(key: sessionKey, nonce: nonce.bytes, aad: [0], tagLength: 4, plaintext: plaintext.bytes)
        self.encryptCounter = (self.encryptCounter + 1) & 0x7fffffffff
        return Data(ret)
    }

    public func decrypt(_ ciphertext: Data) throws -> Data {
//        L.d("\(self)", "decrypt counter", decryptCounter)
        let nonce = decryptCounter.toDecryCounter() + sessionToken
        let ret = try AES.CCM.decrypt(key: sessionKey, nonce: nonce.bytes, aad: [0], tagLength: 4, ciphertext: ciphertext.bytes)
        self.decryptCounter = (self.decryptCounter + 1)
        return Data(ret)
    }
}


extension UInt64{
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt64>.size)
    }

    func toEncryCounter()-> Data{
        var packageCounter: UInt64 = self | 0x8000000000
        let nonce = Data(bytes: &packageCounter, count: 5)
        return nonce
    }
    func toDecryCounter()-> Data{
        var packageCounter: UInt64 = self
        packageCounter = packageCounter & 0x7fffffffff
        let nonce = Data(bytes: &packageCounter, count: 5)
        return nonce
    }
}
