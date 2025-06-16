//
//  Logging.swift
//  sesame2-sdk
//
//  Created by Tse on 2020/02/09.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import os.log

public class L {
    public static func d(_ items: Any..., file: String = #file, function: String = #function,
                 line: Int = #line, tag: String = "hcia") {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "Asia/Tokyo")
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.string(from: Date())
        
        let ismain  = (Thread.isMainThread)  ? "主":"副"
        let content = "\(tag) \(dateFormatter.string(from: Date())) \(items) \(fileName):\(line) \(ismain)"
        print(content)
        
        #endif
    }
}
