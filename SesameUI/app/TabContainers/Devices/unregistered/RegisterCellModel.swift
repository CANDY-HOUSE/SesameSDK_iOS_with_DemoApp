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
    private(set) var dfuButtonImage = "upgrade"
    var isHiddenDfuButton: Bool {
        get {
            if sesame2.deviceStatus == .dfumode {
                return true
            } else {
                return false
            }
        }
    }
    
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
    
    public func currentStatus() -> String {
        sesame2.localizedDescription()
    }
}
