//
//  CHProductModel+.swift
//  SesameUI
//
//  Created by eddy on 2023/12/19.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
#if os(watchOS)
import WatchKit
#endif

extension CHProductModel {
    var is4ByetsPubkeyProductModel: Bool {
        return Int(self.rawValue) - Int(CHProductModel.sesame5.rawValue) >= 0
    }
}
