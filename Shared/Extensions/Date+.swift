//
//  Date+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/7/6.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Date {
    func toYMD() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let strDate = dateFormatter.string(from: self)
        return strDate
    }
}
