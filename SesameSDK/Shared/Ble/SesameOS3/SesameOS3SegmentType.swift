//
//  Sesame5SegmentType.swift
//  SesameSDK
//
//  Created by tse on 2023/3/10.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

struct SesameOS3Payload {
    var itemCode: SesameItemCode
    var data: Data

    init(_ itemCode: SesameItemCode, _ data: Data? = nil) {
        self.itemCode = itemCode
        self.data = data ?? Data()
    }

    init(_ payload: Data) {
        itemCode = SesameItemCode(rawValue: payload[0] ) ?? SesameItemCode.none
        data = payload[1...].copyData
    }

    func toDataWithHeader() -> Data {
        return  itemCode.rawValue.data + data
    }
}

struct SesameOS3PublishPayload {
    let itemCode: SesameItemCode
    let payload: Data

    init(data: Data) {
        var content = data.copyData
        self.itemCode = SesameItemCode(rawValue: content[0...0].toUInt8())!
        self.payload = content[1...].copyData
//        L.d("[ss5][pub]itemCode(4 bytes亂數為編號14)=>",itemCode.rawValue)
    }
}

struct SesameOS3CmdResponsePayload {
    let cmdItCode: SesameItemCode
    let cmdResultCode: SesameResultCode
    var data: Data
    init(_ data: Data) {
        self.cmdItCode = SesameItemCode(rawValue: data[0])!
        self.cmdResultCode = SesameResultCode(rawValue: data[1])!
        self.data = data[2...].copyData
    }
}
