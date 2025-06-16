//
//  ControlDigitalCamera.swift
//  SesameUI
//
//  Created by eddy on 2024/5/30.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

class ControlDigitalCamera: NSObject, UniversalRemoteBehavior {
    
    var xmlConfPathAndName: (fileName: String, eleAttName: String) {
        return ("strings", "strs_dc_key")
    }
    
    func generate(_ completion: @escaping () -> Void) {
        fetchFuncKeys { [weak self] result in
//            self?.funcKeys = result.map { it in
//                return KeyModel(text: NSAttributedString(string: it), type: .button, rawKey: it)
//            }
            completion()
        }
    }
    
    var funcKeys: [any UninKeyConvertor] = []
    
    func sendCommand(_ data: Data, _ device: CHHub3) {
        
    }
}
