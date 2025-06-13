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

protocol HandlerConfigAdapter {
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote)
    func modifyIRDeviceInfo(device: CHHub3, remoteDevice: IRRemote, onResponse: @escaping SesameSDK.CHResult<CHEmpty>)
    func clearHandlerCache()
    func getCurrentState(device: CHHub3, remoteDevice: IRRemote) -> String
    func getCurrentIRDeviceType() -> Int
}
