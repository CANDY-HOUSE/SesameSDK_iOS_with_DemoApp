//
//  HandlerConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

protocol RemoteHandlerAdapter {
    func handleItemClick(item: IrControlItem, hub3DeviceId: String, remoteDevice: IRRemote)
    func modifyIRDeviceInfo(hub3DeviceId: String, remoteDevice: IRRemote, onResponse: @escaping CHResult<CHEmpty>)
    func clearHandlerCache()
    func getCurrentState(remoteDevice: IRRemote) -> String
    func getCurrentIRDeviceType() -> Int
}
