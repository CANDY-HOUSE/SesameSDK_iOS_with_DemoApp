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
        guard let currentDistanceInCentimeter = sesame2.currentDistanceInCentimeter() else {
            return ""
        }
        return "\(currentDistanceInCentimeter) \("co.candyhouse.sesame-sdk-test-app.cm".localized)"
    }
    
    public func bluetoothImage() -> String {
        "bluetooth"
    }
    
    public func modelLabelText() -> String {
        sesame2.deviceId.uuidString
    }
    
    public func currentSesame2Status() -> String {
        CHConfiguration.shared.isDebugModeEnabled() ? sesame2.deviceStatus.description() : ""
    }
}
