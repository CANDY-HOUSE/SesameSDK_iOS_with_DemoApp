//
//  CHSesameBikeDevice+DFU.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

extension CHSesameBikeDevice {
    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        L.d("測試dfu",isRegistered,deviceStatus.description)
        if deviceStatus == .dfumode() {
            L.d("peripheral",peripheral?.identifier ?? "")
            result(.success(CHResultStateBLE(input: self.peripheral)))
        } else if isRegistered {
            if checkBle(result) { return }
            var dfuConfi = Sesame2DFUConfiguration(enabled: true)
            let payload = Sesame2Payload(.update, .enableDFU, dfuConfi.toData())

            sendCommand(payload) { responsePayload in
                if responsePayload.cmdResultCode == .success {
                    result(.success(CHResultStateBLE(input: self.peripheral)))
                } else {
                    result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
                }
            }
        } else {
            L.d("我發送了明文  enableDFU")
            var dfuConfi = Sesame2DFUConfiguration(enabled: true)
            let payload = Sesame2Payload(.update, .enableDFU, dfuConfi.toData())
            
            sendCommand(payload, isCipher: .plaintext) { responsePayload in
                if responsePayload.cmdResultCode == .success {
                    result(.success(CHResultStateBLE(input: self.peripheral)))
                } else {
                    result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
                }
            }
        }
    }

    public func getVersionTag(result: @escaping (CHResult<String>))  {
        if(checkBle(result)){return}
        sendCommand(.init(.read, .versionTag)) { (payload) in
            if let tag = Sesame2VersionTag.fromData(payload.data) {
                if payload.cmdResultCode == .success {
                    result(.success(CHResultStateNetworks(input: tag.gitRevision)))
                } else {
                    result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
                }
            }
        }
    }
}
