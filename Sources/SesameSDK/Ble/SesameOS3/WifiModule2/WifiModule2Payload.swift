//
//  WifiModule2Payload.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

// MARK: - Command
struct WifiModule2Payload {
    var actionCode: WifiModule2ActionCode
    var data: Data?

    init(_ actionCode: WifiModule2ActionCode, _ data: Data? = nil) {
        self.actionCode = actionCode
        self.data = data
    }

    init(_ payload: Data) {
        var content = payload.copyData
        actionCode = WifiModule2ActionCode(rawValue: content[0...0].toUInt8())!
        data = content[1...].copyData
    }

    func toDataWithHeader() -> Data {

        let header = actionCode.rawValue.data

        if let data = data {
            return header + data
        } else {
            return header
        }
    }

    func toDataWithHeader(withCipher cipher: SesameOS3BleCipher) throws  -> Data {
        return  cipher.encrypt(toDataWithHeader())
    }
}



struct WifiModule2PublishPayload {
    let actionCode: UInt8
    let payload: Data
    
    init?(data: Data) {
        let content = data.copyData
        guard let first = content.first else { return nil }
        self.actionCode = first
        self.payload = content.dropFirst().copyData
    }
}

struct WifiModule2CmdResponsePayload {
    let actionCode: WifiModule2ActionCode
    let cmdResultCode: SesameResultCode
    let data: Data
    
    init?(_ data: Data) {
        let content = data.copyData
        guard content.count >= 2, let actionCode = WifiModule2ActionCode(rawValue: content[0]) else { return nil }
        self.actionCode = actionCode
        self.cmdResultCode = SesameResultCode(rawValue: content[1]) ?? .unknown
        self.data = content[2...].copyData
    }
}
