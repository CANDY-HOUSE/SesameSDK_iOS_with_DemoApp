//
//  CHSesameTouchPro+command.swift
//  SesameSDK
//  Created by tse on 2023/5/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

extension CHSesameTouchProDevice {
    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }

    public func getVersionTag(result: @escaping (CHResult<String>))  {
        if(checkBle(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            let versionTag = String(data: response.data, encoding: .utf8) ?? ""
            result(.success(CHResultStateNetworks(input: versionTag)))
        }
    }

    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.reset)) { (responsePayload) in
            self.dropKey { dropResult in
                switch dropResult {
                case .success(_):
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
    }
    
    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else {
            return
        }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { res in
            self.deviceStatus = .unlocked()
        }
    }
    
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>) {
        if (self.checkBle(result)) { return }

        if(device.productModel == .sesame5 || device.productModel == .sesame5Pro || device.productModel == .bikeLock2 ){
            let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            var noDashUUIDData = noDashUUID.hexStringtoData()
            var ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
            sendCommand(.init(.addSesame,noDashUUIDData+ssmSecKa)) { (response) in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }else{
            let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            var base64Key = noDashUUID.hexStringtoData().base64EncodedString()
            base64Key = base64Key.replacingOccurrences(of: "=", with: "", options: [], range: nil)
            let sesame2IR = base64Key.data(using: .utf8)!
            let publicKeyData = device.getKey()!.sesame2PublicKey.hexStringtoData()
            var ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
            let allKey = sesame2IR + publicKeyData + ssmSecKa
            sendCommand(.init(.addSesame, allKey)) { (response) in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }
    }

    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>) {
        if (self.checkBle(result)) { return }
        L.d("self.sesame2Keys[tag]",self.sesame2Keys[tag])
        if let lockStatusData = self.sesame2Keys[tag], let lockStatus = UInt8(lockStatusData), lockStatus == 0x04 {
            L.d("rm ss4")

            let noDashUUID = tag.replacingOccurrences(of: "-", with: "")
            let base64String = noDashUUID.hexStringtoData().base64EncodedString().replacingOccurrences(of: "=", with: "")
            let ssmIRData = Data(base64String.utf8)
            sendCommand(.init(.removeSesame,ssmIRData)) { (response) in
                L.d("rm ss4 ok")

                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        } else {
            L.d("rm ss5")
            let noDashUUID = tag.replacingOccurrences(of: "-", with: "", options: [], range: nil)
            sendCommand(.init(.removeSesame,noDashUUID.hexStringtoData())) { (response) in
                L.d("rm ss5 ok")
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
        }
    }

    func fingerPrints( result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.SSM_OS3_FINGERPRINT_GET)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func fingerPrintDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.SSM_OS3_FINGERPRINT_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func fingerPrintsChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>) ) {
        if (self.checkBle(result)) { return }

        let idData = ID.hexStringtoData()
        let payload = Data([UInt8(idData.count)]) + idData + name.bytes
        L.d("TouchDevice payload =>",payload.toHexLog())
        sendCommand(.init(.SSM_OS3_FINGERPRINT_CHANGE, payload)) { _ in
            L.d("[TouchDevice][fingerPrintsChange][ok]")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func fingerPrintModeGet(result: @escaping (CHResult<UInt8>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_FINGERPRINT_MODE_GET)) { response in
            L.d("[TouchDevice][fingerPrintModeGet]",response.data[0])
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }

    func fingerPrintModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_FINGERPRINT_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }


    func cards(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_GET)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardsDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardsChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        let idData = ID.hexStringtoData()
        let payload = Data([UInt8(idData.count)]) + idData + name.bytes
        L.d("TouchDevice",payload.toHexLog())
        sendCommand(.init(.SSM_OS3_CARD_CHANGE, payload)) { _ in
            L.d("[TouchDevice][fingerPrintsChange][ok]")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func cardsModeGet(result: @escaping (CHResult<UInt8>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }

    func cardsModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_CARD_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodes(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_GET)) { _ in
            L.d("SSM_OS3_PASSCODE_GET ok")
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeDelete(ID: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_DELETE,ID.hexStringtoData())) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeChange(ID: String, name: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        let idData = ID.hexStringtoData()
        let payload = Data([UInt8(idData.count)]) + idData + name.bytes
        sendCommand(.init(.SSM_OS3_PASSCODE_CHANGE, payload)) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

    func passCodeModeGet(result: @escaping (CHResult<UInt8>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_MODE_GET)) { response in
            result(.success(CHResultStateNetworks(input: response.data[0])))
        }
    }

    func passCodeModeSet(mode: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }

        sendCommand(.init(.SSM_OS3_PASSCODE_MODE_SET,Data([mode]))) { _ in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }

}
