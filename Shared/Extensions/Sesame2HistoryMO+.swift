//
//  Sesame2HistoryMO+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/26.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Sesame2HistoryMO {
    var sortKey: UInt {
        UInt(date!.timeIntervalSince1970) * UInt(pow(10.0, 10.0)) + UInt(recordID)
    }
}
