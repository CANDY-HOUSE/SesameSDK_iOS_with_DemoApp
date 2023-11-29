//
//  CHSesameBikeDevice+Setting.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2020/12/31.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBikeDevice {
    
    func defaultMechSetting() -> CHSesameBikeMechSettings {
        CHSesameBikeMechSettings(secs: .init(forward: 10, hold: 2, backward: 10))
    }
    
    func setUnlockSecs(historytag: Data?,
                       secs: CHSesameBikeUnlockSecs,
                       result: @escaping (CHResult<CHEmpty>)) {
        
        if checkBle(result) { return }
        
        let seconds = BikeLockUnlockSecs(forward: UInt8(secs.forward * 10),
                                         hold: UInt8(secs.hold * 10),
                                         backward: UInt8(secs.backward * 10))
        
        var mechSettingCopy = (mechSetting as? CHSesameBikeMechSettings) ?? defaultMechSetting()
        mechSettingCopy.secs = seconds
        
        let tmpSetting = mechSettingCopy.toData()
        
        let tagCount_hisTag = Data.createHistag(historytag ?? sesame2KeyData?.historyTag)
        let payload = tmpSetting + tagCount_hisTag
        
        sendCommand(.init(.update, .mechSetting, payload)) { (responsePayload) in
            if responsePayload.cmdResultCode == .success {
                self.mechSetting = CHSesameBikeMechSettings.fromData(tmpSetting)
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func getUnlockSecs(_ result: @escaping CHResult<CHSesameBikeUnlockSecs>) {
        if checkBle(result) { return }
        
        sendCommand(.init(.read, .mechSetting)) { (payload) in
            if let mechSetting = CHSesameBikeMechSettings.fromData(payload.data) {
                self.mechSetting = mechSetting
                result(.success(CHResultStateBLE(input: self.mechSetting!.unlockSecs)))
            }
        }
    }
}
