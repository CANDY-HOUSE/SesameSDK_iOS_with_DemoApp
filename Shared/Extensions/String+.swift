//
//  String+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

private class LanguageBundle {
    static let bundle: Bundle = Bundle(for: LanguageBundle.self)
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

    var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    public var localized: String{
        return NSLocalizedString(self,
                                 bundle: LanguageBundle.bundle,
                                 value: "",
                                 comment: "")
    }
    
    func noDashtoUUID() -> UUID? {
        var input = self
        input.insert("-", at: input.index(input.startIndex, offsetBy: 20))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 16))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 12))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 8))
        return UUID(uuidString: input)
    }
    
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
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
