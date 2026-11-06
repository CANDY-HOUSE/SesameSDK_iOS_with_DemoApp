//
//  Sesame5SegmentType.swift
//  SesameSDK
//
//  Created by tse on 2023/3/10.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import Foundation
struct SesameOS3Payload {
    var itemCode: SesameItemCode
    var data: Data

    init(_ itemCode: SesameItemCode, _ data: Data? = nil) {
        self.itemCode = itemCode
        self.data = data ?? Data()
    }

    init(_ payload: Data) {
        let content = payload.copyData
        itemCode = content.first.flatMap { SesameItemCode(rawValue: $0) } ?? SesameItemCode.none
        data = content.count > 1 ? content[1...].copyData : Data()
    }

    func toDataWithHeader() -> Data {
        return  itemCode.rawValue.data + data
    }
}

struct SesameOS3PublishPayload {
    let itemCode: SesameItemCode
    let payload: Data

    init?(data: Data) {
        guard data.count >= 1 else { return nil }
        var content = data.copyData
        self.itemCode = SesameItemCode(rawValue: content[0...0].toUInt8()) ?? SesameItemCode.none
        self.payload = content[1...].copyData
//        L.d("[ss5][pub]itemCode(4 bytes亂數為編號14)=>",itemCode.rawValue)
    }
}

struct SesameOS3CmdResponsePayload {
    let cmdItCode: SesameItemCode
    let cmdResultCode: SesameResultCode
    var data: Data
    init?(_ data: Data) {
        let content = data.copyData
        guard content.count >= 2 else { return nil }
        self.cmdItCode = SesameItemCode(rawValue: content[0]) ?? SesameItemCode.none
        self.cmdResultCode = SesameResultCode(rawValue: content[1]) ?? .unknown
        self.data = content[2...].copyData
    }
}
