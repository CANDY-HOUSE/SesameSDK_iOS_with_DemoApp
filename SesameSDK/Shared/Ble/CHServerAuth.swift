//
//  CHServerAuth.swift
//  SesameSDK
//
//  Created by JOi Chao on 2023/9/11.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import Security
import CryptoKit

struct KeyQues {
    var ak: String
    var n: String
    var e: String
    var t: UInt16
}

struct KeyResp {
    var sig1: String
    var st: String
    var pubkey: String
}

class CHServerAuth {
    
    static let serverKey: String =  "04a040fcc7386b2a08304a3a2f0834df575c936794209729f0d42bd84218b35803932bea522200b2ebcbf17ab57c4509b4a3f1e268b2489eb3b75f7a765adbe181"
   
    static func getRegisterKey(data: KeyQues) -> KeyResp {
        let keyBytes = "Sesame2_key_pair".data(using: .utf8)!
        let erBytes = Data(hex: data.e)
        let oneKey = CC.CMAC.AESCMAC(erBytes, key: keyBytes)
        let twoKey = CC.CMAC.AESCMAC(erBytes, key: oneKey)
        let priKey = oneKey + twoKey

        guard let serverPub = Data(hexString: serverKey) else {fatalError("Invalid hex string")}
            
        let privateKey = try! P256.KeyAgreement.PrivateKey(rawRepresentation: priKey)
        let pair = privateKey.publicKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()
//        let rawPrikey = privateKey.rawRepresentation // for log
//        let hexstring = rawPrikey.map { String(format: "%02x", $0) }.joined() // toHexString
        
        let ecdh = try! P256.KeyAgreement.PublicKey(rawRepresentation: serverPub.dropFirst()) // 扣掉04前綴
        let sharedSecret = try! privateKey.sharedSecretFromKeyAgreement(with: ecdh).withUnsafeBytes { Data($0) }
        let secret = sharedSecret.prefix(32)
        var serverToken = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, serverToken.count, &serverToken)
        let stString = Data(serverToken).base64EncodedString()
        
        let decode = Data(base64Encoded: data.n)!
        let decodeToken = Data(base64Encoded: data.ak)!
        let sessionToken = Data(serverToken) + decode
        
        let msg = decodeToken + sessionToken

        let sig1 = CC.CMAC.AESCMAC(msg, key: secret)
        let sigString = Data(sig1.prefix(4)).base64EncodedString()
        let pubString = Data(hex: pair).base64EncodedString()

        return KeyResp(sig1: sigString, st: stString, pubkey: pubString)
    }
}

extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0..<length {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
