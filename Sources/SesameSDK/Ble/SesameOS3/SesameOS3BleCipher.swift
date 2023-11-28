//
//  SesameOS3BleCipher.swift
//  SesameSDK
//
//  Created by tse on 2023/5/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

class SesameOS3BleCipher {
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

    public func encrypt(_ plaintext: Data)  -> Data {
        let ret = try! AES.CCM.encrypt(key: sessionKey, nonce: (encryptCounter.data + sessionToken).bytes,aad:[0], tagLength:4,plaintext: plaintext.bytes)
        encryptCounter = encryptCounter + 1
        return Data(ret)
    }

    public func decrypt(_ ciphertext: Data)  -> Data { 
        do {
            let ret = try AES.CCM.decrypt(key: sessionKey, nonce: (decryptCounter.data + sessionToken).bytes,aad:[0],tagLength:4,ciphertext: ciphertext.bytes)
            decryptCounter = decryptCounter + 1
            return Data(ret)
        } catch {
            L.d("解密錯誤 ！！！", error)
        }
        return Data()
    }
}
