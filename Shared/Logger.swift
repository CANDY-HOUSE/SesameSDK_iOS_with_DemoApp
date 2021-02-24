//
//  DataExtention.swift
//  sesame-sdk
//
//  Created by tse on 2019/8/6.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import os.log

class L {
    static func d(_ items: Any..., file: String = #file, function: String = #function,
                  line: Int = #line, tag: String = "hcia") {
        
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        dateFormatter.timeZone = TimeZone(abbreviation: "Asia/Tokyo")
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.string(from: Date())
        
        let ismain  = (Thread.isMainThread)
        let content = " \(items) \(ismain ? "主":"副") \(fileName) : \(line) \(tag)"
        if #available(iOS 12.0, *) {
            os_log("%{public}s", content)
        } else {
            print(dateFormatter.string(from: Date()), items,ismain ? "主":"副","\(fileName):\(line)",tag)
        }
        #endif
    }
}
