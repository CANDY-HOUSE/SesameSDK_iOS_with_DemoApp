//
//  ControlVacuumCleaner.swift
//  SesameUI
//
//  Created by eddy on 2024/5/30.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

class ControlVacuumCleaner: NSObject, UniversalRemoteBehavior {
    
    var xmlConfPathAndName: (fileName: String, eleAttName: String) {
        return ("", "")
    }
    
    func generate(_ completion: @escaping () -> Void) {

    }
    
    var funcKeys: [any UninKeyConvertor] = []
    
    func sendCommand(_ data: Data, _ device: CHHub3) {
        
    }
}
