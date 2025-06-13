//
//  ControlDVDPlayer.swift
//  SesameUI
//
//  Created by eddy on 2024/5/30.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

class ControlDVDPlayer: NSObject, UniversalRemoteBehavior {
    
    var xmlConfPathAndName: (fileName: String, eleAttName: String) {
        return ("strings", "strs_dvd_key")
    }
    
    func generate(_ completion: @escaping () -> Void) {
        fetchFuncKeys { [weak self] result in
            self?.funcKeys = result
            completion()
        }
    }
    
    var funcKeys: [any UninKeyConvertor] = []
    
    func sendCommand(_ data: Data, _ device: CHHub3) {
        
    }
}
