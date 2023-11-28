//
//  CHSesameTouchPro.swift
//  SesameSDK
//
//  Created by tse on 2023/5/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth


public protocol CHSesameTouchPro: CHDevice ,CHSesameConnector{
    var mechSetting: CHSesameTouchProMechSettings? { get }
    func getVersionTag(result: @escaping (CHResult<String>))

    func fingerPrints(result: @escaping(CHResult<CHEmpty>))
    func fingerPrintDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    func fingerPrintsChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func fingerPrintModeGet(result  : @escaping(CHResult<UInt8>))
    func fingerPrintModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))

    func cards(result: @escaping(CHResult<CHEmpty>))
    func cardsDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    func cardsChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func cardsModeGet(result  : @escaping(CHResult<UInt8>))
    func cardsModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))


    func passCodes(result: @escaping(CHResult<CHEmpty>))
    func passCodeDelete(ID: String, result  : @escaping(CHResult<CHEmpty>))
    func passCodeChange(ID: String, name: String, result  : @escaping(CHResult<CHEmpty>))
    func passCodeModeGet(result  : @escaping(CHResult<UInt8>))
    func passCodeModeSet(mode: UInt8, result  : @escaping(CHResult<CHEmpty>))
}

public struct CHSesameTouchProMechSettings {}

public protocol  CHSesameTouchProDelegate : AnyObject{

    func onFingerPrintReceiveStart(device: CHSesameConnector)
    func onFingerPrintReceiveEnd(device: CHSesameConnector)
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) 
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)

    func onCardReceiveStart(device: CHSesameConnector)
    func onCardReceiveEnd(device: CHSesameConnector)
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)

    func onPassCodeReceiveStart(device: CHSesameConnector)
    func onPassCodeReceiveEnd(device: CHSesameConnector)
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8)
    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8)

}

public extension  CHSesameTouchProDelegate  {

    func onFingerPrintReceiveStart(device: CHSesameConnector){}
    func onFingerPrintReceiveEnd(device: CHSesameConnector){}
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}

    func onCardReceiveStart(device: CHSesameConnector){}
    func onCardReceiveEnd(device: CHSesameConnector){}
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}

    func onPassCodeReceiveStart(device: CHSesameConnector){}
    func onPassCodeReceiveEnd(device: CHSesameConnector){}
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8){}
    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8){}

}

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
        cardName = String(data: data.subdata(in: nameIndex + 1..<(nameIndex + Int(nameLength) + 1)), encoding: .utf8) ?? ""
    }
}
