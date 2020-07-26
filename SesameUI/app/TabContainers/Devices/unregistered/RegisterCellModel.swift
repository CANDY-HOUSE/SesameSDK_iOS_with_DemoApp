//
//  RegisterCellModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class RegisterCellModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    private var sesame2: CHSesame2
    
    public init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
    }
    
    public func ssiText() -> String {
        (sesame2.rssi == nil) ? "0%":"\(sesame2.rssi!.intValue + 130)%"
    }
    
    public func bluetoothImage() -> String {
        "bluetooth"
    }
    
    public func modelLabelText() -> String {
        sesame2.deviceId.uuidString
    }
    
    public func currentStatus() -> String {
        sesame2.localizedDescription()
    }
}
