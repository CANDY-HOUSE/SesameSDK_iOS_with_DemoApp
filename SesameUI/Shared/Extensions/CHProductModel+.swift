//
//  CHProductModel+.swift
//  SesameUI
//
//  Created by eddy on 2023/12/19.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
import WatchKit
#endif

extension CHProductModel {
    var is4ByetsPubkeyProductModel: Bool {
        return Int(self.rawValue) - Int(CHProductModel.sesame5.rawValue) >= 0
    }
    
    var defaultMatterRole: MatterProductModel {
        switch self {
        case .sesame5, .sesame5Pro, .sesame5US, .bikeLock2:
            return .doorLock
        case .sesameBot2:
            return .onOffSwitch
        default:
            return .none
        }
    }
}
