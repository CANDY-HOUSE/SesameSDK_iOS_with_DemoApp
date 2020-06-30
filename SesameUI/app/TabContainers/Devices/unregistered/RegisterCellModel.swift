//
//  RegisterCellModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class RegisterCellModel {
    private var ssm: CHSesameBleInterface
    
    public init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
    }
    
    public func ssiText() -> String {
        "\(ssm.rssi.intValue + 130)%"
    }
    
    public func bluetoothImage() -> String {
        "bluetooth"
    }
    
    public func modelLabelText() -> String {
        ssm.model.rawValue.localStr
    }
}
