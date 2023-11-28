//
//  CHDeviceManager+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

extension CHDeviceManager {
    /// 設定所有Sesame device的 history tag
    func setHistoryTag() {
        let historyTag = Sesame2Store.shared.getHistoryTag()
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(chDevices) = getResult {
                for sesameLock in chDevices.data.compactMap({ $0 as? CHSesameLock }) {
                    sesameLock.setHistoryTag(historyTag, result: {_ in})
                }
            }
        }
    }
    
    func dropAllLocalKeys(complateHandler: (()->Void)? = nil) { //登出時，清除所有本地裝置列表
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                for device in devices.data {
                    device.dropKey { _ in}
                    Sesame2Store.shared.deletePropertyFor(device)
                    }
                complateHandler?()
            }
        }
    }
}
