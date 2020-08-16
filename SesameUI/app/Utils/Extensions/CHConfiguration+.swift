//
//  CHConfiguration+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/8/9.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK


extension CHConfiguration {
    func isHistoryStorageEnabled() -> Bool {
        guard let isEnabled = CHConfiguration.shared.getValueForKey("EnableHistoryStore") as? Bool else {
            return false
        }
        return isEnabled
    }
}
