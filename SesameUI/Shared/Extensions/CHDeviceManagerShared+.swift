//
//  CHDeviceManager+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

extension CHDeviceManager {
    /// 設定所有Sesame device的 history tag
    func setHistoryTag() {
        let historyTag = Sesame2Store.shared.getHistoryTag()// for os2
        let userSubTag = Sesame2Store.shared.getSubUuid()// for os3
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(chDevices) = getResult {
                for sesameLock in chDevices.data.compactMap({ $0 as? CHSesameLock }) {
                    L.d("標籤,CHDeviceManager =>", historyTag)
                    if sesameLock is CHSesame5 {
                        sesameLock.setHistoryTag(userSubTag, result: {_ in})
                    } else {
                        sesameLock.setHistoryTag(historyTag, result: {_ in})
                    }
                }
            }
        }
    }
    
    func dropAllLocalKeys(complateHandler: (()->Void)? = nil) { // 登出時，清除所有本地裝置列表
            CHDeviceManager.shared.getCHDevices { result in
                L.d("[登出]dropAllLocalKeys <=")
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
