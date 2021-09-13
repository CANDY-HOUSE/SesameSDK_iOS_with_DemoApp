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
    
    func dropAllLocalKeys(complateHandler: (()->Void)? = nil) {
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                for device in devices.data {
                    device.dropKey { _ in
                        
                    }
                    Sesame2Store.shared.deletePropertyFor(device)
                }
                complateHandler?()
            }
        }
    }
}
