//
//  DataExtention.swift
//  sesame-sdk
//
//  Created by tse on 2019/8/6.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation

class L {
    static func d(_ items: Any..., file: String = #file, function: String = #function,
                  line: Int = #line, tag: String = "hcia") {
        
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let ismain  = (Thread.isMainThread)
        let dateFormatter = DateFormatter()
        //        dateFormatter.dateFormat = "mm:ss.SSSS"
        //        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.string(from: Date())
        print(dateFormatter.string(from: Date()),"\(fileName):\(line):", items ,ismain ? "主":"副")
        #endif
    }
}
