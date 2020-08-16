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
    private var sesame2: CHSesame2
    
    @Published var title = ""
    @Published var image = ""
    
    init(device: CHSesame2) {
        self.sesame2 = device
        self.uuid = device.deviceId
        title = device.deviceId.uuidString
        image = "Icon"
    }
    
    func isSelected(uuid: UUID) -> Bool {
        uuid == sesame2.deviceId
    }
}
