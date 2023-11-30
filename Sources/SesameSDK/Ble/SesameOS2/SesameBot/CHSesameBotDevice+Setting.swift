//
//  CHSesameBotDevice+Setting.swift
//  SesameSDK
//
//  Created by YuHan Hsiao on 2020/12/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

extension CHSesameBotDevice {
    func updateSetting(historytag: Data?, setting: CHSesameBotMechSettings, result: @escaping CHResult<CHEmpty>) {
        var mechSettingCopy = setting
        let tmpSetting = mechSettingCopy.toData()
        let tagCountHisTag = Data.createHistag(historytag ?? sesame2KeyData?.historyTag)
        let payload = tmpSetting + tagCountHisTag
        
        sendCommand(.init(.update, .mechSetting, payload)) { (responsePayload) in
            if responsePayload.cmdResultCode == .success {
                self.mechSetting = CHSesameBotMechSettings.fromData(tmpSetting)
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
}
