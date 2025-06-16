//
//  String+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
extension String {
    public var localized: String{
        guard let preferredLanguage = Bundle.main.preferredLocalizations.first else {
            return self // 返回原始字符串作为默认值
        }
        
        // 获取对应语言的 lproj 文件路径
        guard let localizationPath = Bundle.main.path(forResource: preferredLanguage, ofType: "lproj"),
              let bundle = Bundle(path: localizationPath) else {
            return self // 返回原字符串作为默认值
        }
        
        return NSLocalizedString(self,
                                 bundle: bundle,
                                 value: "",
                                 comment: "")
    }
    
    func localizedTime(dateFormat: String = "yyyy-MM-dd@HH:mm:ss") -> String? {
         guard let milliseconds = Int64(self) else {
             print("Invalid milliseconds timestamp")
             return nil
         }
         let date = Date(timeIntervalSince1970: Double(milliseconds) / 1000.0)
         let formatter = DateFormatter()
         formatter.dateFormat = dateFormat
         formatter.locale = Locale.current
         formatter.timeZone = TimeZone.current
         return formatter.string(from: date)
     }
}

extension String {
    func dataFromHexadecimalString() -> Data? {
        let trimmedString = self.trimmingCharacters(
            in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(
                of: " ", with: "")

        // make sure the cleaned up string consists solely of hex digits,
        // and that we have even number of them
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: trimmedString, options: [],
                                     range: NSRange(location: 0,
                                                    length: trimmedString.count))
        guard found != nil &&
            found?.range.location != NSNotFound &&
            trimmedString.count % 2 == 0 else {
                return nil
        }

        // everything ok, so now let's build Data
        var data = Data(capacity: trimmedString.count / 2)
        var index: String.Index? = trimmedString.startIndex

        while let i = index {
            let byteString = String(trimmedString[i ..< trimmedString.index(i, offsetBy: 2)])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append([num] as [UInt8], count: 1)

            index = trimmedString.index(i, offsetBy: 2, limitedBy: trimmedString.endIndex)
            if index == trimmedString.endIndex { break }
        }

        return data
    }
    
    func noDashtoUUID() -> UUID? {
        var input = self
        input.insert("-", at: input.index(input.startIndex, offsetBy: 20))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 16))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 12))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 8))
        return UUID(uuidString: input)
    }
}

extension String {
    func hexStringToIntStr() -> String {
        var tmp = ""
        for (index, value) in self.enumerated() {
            if index % 2 == 1 {
                tmp.append(value)
            }
        }
        return tmp
    }
    
    func hexStringToBytes() -> [UInt8]? {
        let hexString = self
        guard !hexString.isEmpty else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity((hexString.count + 1) / 2)
        var modifiedHexString = hexString
        if hexString.count % 2 != 0 {
            modifiedHexString = "0" + hexString
        }
        var index = modifiedHexString.startIndex
        while index < modifiedHexString.endIndex {
            let nextIndex = modifiedHexString.index(index, offsetBy: 2)
            if nextIndex <= modifiedHexString.endIndex, let byte = UInt8(modifiedHexString[index..<nextIndex], radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
}
