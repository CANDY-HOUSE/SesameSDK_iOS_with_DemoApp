//
//  CHSesameTouchPro+.swift
//  SesameUI
//
//  Created by eddy on 2024/10/12.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

extension CHSesameBiometricDevice {
    
    var displayedState: NSAttributedString? {
        get {
            guard (self.productModel == .openSensor2 || (self.productModel == .openSensor && deviceStatus == .noBleSignal())) else {
                return nil
            }
            
            if let data = mechStatus?.data {
                do {
                    let state = try JSONDecoder().decode(OpenSensorData.self, from: data)
                    return createOpensensorStateText(status: state.Status)
                } catch {}
            }
            
            if let stateInfo = self.stateInfo,
               let status = stateInfo.CHSesame2Status {
                return createOpensensorStateText(status: status)
            }
            
            return nil
        }
    }
    
    private func createOpensensorStateText(status: String) -> NSAttributedString {
        NSAttributedString(string: status, attributes: [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.lockGray
        ])
    }
}
