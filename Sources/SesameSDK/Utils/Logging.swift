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
    
    private enum LogLevel: String {
        case debug = "🐞DEBUG"
        case info = "ℹ️INFO"
        case warning = "⚠️WARN"
        case error = "❌ERROR"
    }
    
    // 主日志入口
    private static func log(
        _ level: LogLevel = .debug,
        _ items: Any...,
        tag: String = "CANDYHOUSE",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Release builds print nothing: SDK logs may contain keys, tokens or Wi-Fi credentials.
#if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "Asia/Tokyo")
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let dateString = dateFormatter.string(from: Date())
        let isMain = Thread.isMainThread ? "主" : "副"
        let msg = items.map { "\($0)" }.joined(separator: " ")
        let logContent = "[\(level.rawValue)] (\(tag)) \(dateString) \(msg) [\(fileName):\(line) \(isMain)] \(function)"
        
        // 控制台输出
        print(logContent)
#endif
    }
    
    public static func d(_ items: Any..., tag: String = "CANDYHOUSE", file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, items, tag: tag, file: file, function: function, line: line)
    }
    public static func i(_ items: Any..., tag: String = "CANDYHOUSE", file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, items, tag: tag, file: file, function: function, line: line)
    }
    public static func w(_ items: Any..., tag: String = "CANDYHOUSE", file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, items, tag: tag, file: file, function: function, line: line)
    }
    public static func e(_ items: Any..., tag: String = "CANDYHOUSE", file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, items, tag: tag, file: file, function: function, line: line)
    }
}

