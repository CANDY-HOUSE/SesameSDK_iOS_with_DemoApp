//
//  SesameListCellModel.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import SesameWatchKitSDK
import SwiftUI
import Combine

class Sesame2ListCellModel: ObservableObject {
    var uuid: UUID!
    private var device: CHDevice
    
    @Published var title = ""
    @Published var image = ""
    
    init(device: CHDevice) {
        self.device = device
        self.uuid = device.deviceId
        title = device.deviceName
        image = "Icon"
    }
    
    func isSelected(uuid: UUID) -> Bool {
        return uuid == device.deviceId
    }
}
