//
//  CHSesameTouchCard.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
public class CHSesameTouchCard {
    let cardType: UInt8
    let idLength: UInt8
    let cardID: String
    let nameIndex: Int
    let nameLength: UInt8
    let cardName: String

    init(data: Data) {
        cardType = data[0]
        idLength = data[1]
        cardID = data.subdata(in: 2..<(Int(idLength) + 2)).toHexString()
        nameIndex = Int(idLength) + 2
        nameLength = data[nameIndex]
        cardName = String(data: data.subdata(in: nameIndex + 1..<(nameIndex + Int(nameLength) + 1)), encoding: .utf8) ?? data.subdata(in: nameIndex + 1..<(nameIndex + Int(nameLength) + 1)).toHexString()

    }
}
