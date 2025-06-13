//
//  KeyLevel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/24.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

enum KeyLevel: Int {
    case owner = 0
    case manager = 1
    case guest = 2
    case error = -1

    func description() -> String {
        switch self {
        case .owner:
            return "co.candyhouse.sesame2.owner".localized
        case .manager:
            return "co.candyhouse.sesame2.manager".localized
        case .guest:
            return "co.candyhouse.sesame2.member".localized
        case .error:
            return "error"
        }
    }

}
