//
//  IRType.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension IRType {
    static var allTypes: [Int] {
        return [
            IRType.DEVICE_REMOTE_AIR,
            IRType.DEVICE_REMOTE_TV,
            IRType.DEVICE_REMOTE_LIGHT,
            IRType.DEVICE_REMOTE_FANS,
            IRType.DEVICE_REMOTE_CUSTOM
        ]
    }
}
