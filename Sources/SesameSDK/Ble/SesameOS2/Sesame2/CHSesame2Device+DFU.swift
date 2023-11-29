//
//  CHSesame2Device+DFU.swift
//  SesameSDK
//
//  Created by tse on 2020/7/25.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

extension CHSesame2Device {
    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        if(deviceStatus == .dfumode()){
            result(.success(CHResultStateBLE(input: self.peripheral)))
        }else if(isRegistered){
            if(checkBle(result)){return}
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
        if(checkBle(result)){ return }
        sendCommand(.init(.read, .versionTag)) { (payload) in
            
            if let tag = Sesame2VersionTag.fromData(payload.data) {
                L.d("[ss3][getVersionTag]=>", tag.gitRevision)
                if payload.cmdResultCode == .success {
                    result(.success(CHResultStateNetworks(input: tag.gitRevision)))
                } else {
                    result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
                }
            }   
        }
    }
}
