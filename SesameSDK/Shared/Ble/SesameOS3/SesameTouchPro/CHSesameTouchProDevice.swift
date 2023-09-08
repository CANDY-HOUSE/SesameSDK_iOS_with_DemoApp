//
//  CHSesameTouchProDevice.swift
//  SesameSDK
//
//  Created by tse on 2023/5/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

class CHSesameTouchProDevice: CHSesameOS3, CHDeviceUtil, CHSesameTouchPro {

    var sesame2Keys = [String: String]() {
        didSet {
            (self.delegate as? CHSesameConnectorDelegate)?.onSesame2KeysChanged(device: self, sesame2keys: sesame2Keys)
        }
    }

    var mechSetting: CHSesameTouchProMechSettings?
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement  else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }
    
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {

        case .SSM_OS3_PASSCODE_CHANGE:
            L.d("SSM_OS3_PASSCODE_CHANGE")
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onPassCodeChanged(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_PASSCODE_NOTIFY:
            L.d("SSM_OS3_PASSCODE_NOTIFY")
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onPassCodeReceive(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_PASSCODE_LAST:
            L.d("SSM_OS3_PASSCODE_LAST")
            (self.delegate as? CHSesameTouchProDelegate)?.onPassCodeReceiveEnd(device: self)
            
        case .SSM_OS3_PASSCODE_FIRST:
            L.d("SSM_OS3_PASSCODE_FIRST")
            (self.delegate as? CHSesameTouchProDelegate)?.onPassCodeReceiveStart(device: self)
            
        case .SSM_OS3_CARD_CHANGE:
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onCardChanged(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_CARD_NOTIFY:
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onCardReceive(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_CARD_LAST:
            (self.delegate as? CHSesameTouchProDelegate)?.onCardReceiveEnd(device: self)
            
        case .SSM_OS3_CARD_FIRST:
            (self.delegate as? CHSesameTouchProDelegate)?.onCardReceiveStart(device: self)
            
        case .SSM_OS3_FINGERPRINT_CHANGE:
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onFingerPrintChanged(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_FINGERPRINT_NOTIFY:
            let card = CHSesameTouchCard(data:data)
            (self.delegate as? CHSesameTouchProDelegate)?.onFingerPrintReceive(device:self, id: card.cardID, name: card.cardName, type: card.cardType)
            
        case .SSM_OS3_FINGERPRINT_LAST:
            (self.delegate as? CHSesameTouchProDelegate)?.onFingerPrintReceiveEnd(device: self)
            
        case .SSM_OS3_FINGERPRINT_FIRST:
            (self.delegate as? CHSesameTouchProDelegate)?.onFingerPrintReceiveStart(device: self)

        case .mechStatus:
            mechStatus = CHSesameTouchProMechStatus.fromData(data)!
            L.d("[TPO][battery]",mechStatus?.getBatteryPrecentage())

        case .pubKeySesame:
            self.sesame2Keys.removeAll()
            let dividedData = data.divideArray(chunkSize: 23)
            for keyData in dividedData {
                let lockStatus = keyData[22]
                if lockStatus != 0 {
                    if keyData[21] == 0x00 {
                        let deviceIDData = keyData[0...15]
                        if let sesame2DeviceId = deviceIDData.toHexString().noDashtoUUID() {
                            sesame2Keys[sesame2DeviceId.uuidString] = "05"///ss5
                        }
                    } else {
                        let ss2Ir22 = keyData[0...21]
                        if let decodedData = Data(base64Encoded: (String(data: ss2Ir22, encoding: .utf8)! + "==")) {
                            if let sesame2DeviceId = decodedData.toHexString().noDashtoUUID() {
                                sesame2Keys[sesame2DeviceId.uuidString] = "04"///ss3/4
                            }
                        }
                    }
                }
            }
            L.d("sesame2Keys",sesame2Keys)

        default:
            L.d("!![ss5][pub][\(itemCode.rawValue)]")
        }
    }
}

struct CHSesameTouchProMechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let target: Int16
    let position: Int16
    let flags: UInt8
    var data: Data {battery.data + target.data + position.data  + flags.data}
    var isClutchFailed: Bool { return false}
    var isInLockRange: Bool { return false }
    var isInUnlockRange: Bool { return false}
    var isStop: Bool? { return false }
    var isBatteryCritical: Bool { return false}

    public func getBatteryVoltage() -> Float {
        return Float(battery) * 2 / 1000
    }

    static func fromData(_ buf: Data) -> CHSesameTouchProMechStatus? {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
