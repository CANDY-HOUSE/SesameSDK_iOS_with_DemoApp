//
//  AES.swift
//  sesame2-sdk
//
//  Created by Cerberus on 2019/09/04.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation

class AES {


    class CCM {
        static func encrypt(key: [UInt8], nonce: [UInt8], aad: [UInt8], tagLength: Int, plaintext: [UInt8]) throws -> [UInt8] {
            
            let keyRef = UnsafePointer<UInt8>(key)
            let nonceRef = UnsafePointer<UInt8>(nonce)
            let aadRef = UnsafePointer<UInt8>(aad)
            let plaintextRef = UnsafePointer<UInt8>(plaintext)

            let ciphertextRef = UnsafeMutablePointer<UInt8>.allocate(capacity: plaintext.count)
            let authRef = UnsafeMutablePointer<UInt8>.allocate(capacity: tagLength)
            defer {
                ciphertextRef.deallocate()
                authRef.deallocate()
            }
            
            let ret = aes_ccm_ae(keyRef, key.count,
                                 nonceRef, tagLength,
                                 plaintextRef, plaintext.count,
                                 aadRef, aad.count,
                                 ciphertextRef, authRef)
            if ret == 0 {
                return (
                    Array(UnsafeBufferPointer(start: ciphertextRef, count: plaintext.count)) + Array(UnsafeBufferPointer(start: authRef, count: tagLength)))
            } else {
                throw AESError.EncryptError
            }
        }

        static func decrypt(key: [UInt8], nonce: [UInt8], aad: [UInt8], tagLength: Int, ciphertext: [UInt8]) throws -> [UInt8] {

            let keyRef = UnsafePointer<UInt8>(key)
            let nonceRef = UnsafePointer<UInt8>(nonce)
            let aadRef = UnsafePointer<UInt8>(aad)
            let ciphertextRef = UnsafePointer<UInt8>(ciphertext)

            let plaintextRef = UnsafeMutablePointer<UInt8>.allocate(capacity: ciphertext.count - tagLength)
            defer {
                plaintextRef.deallocate()
            }
            let ret = aes_ccm_ad(keyRef, key.count,
                                 nonceRef, tagLength,
                                 ciphertextRef, ciphertext.count - tagLength,
                                 aadRef, aad.count,
                                 ciphertextRef + ciphertext.count - tagLength, plaintextRef)
            if ret == 0 {
                return Array(UnsafeBufferPointer(start: plaintextRef, count: ciphertext.count - tagLength))
            } else {
                throw AESError.DecryptError
            }
        }
    }
}


enum AESError: Error {
    case EncryptError, DecryptError
}
