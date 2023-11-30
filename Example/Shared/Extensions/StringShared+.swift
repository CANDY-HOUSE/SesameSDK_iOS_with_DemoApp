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
        return NSLocalizedString(self,
                                 bundle: Bundle(for: L.self),
                                 value: "",
                                 comment: "")
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
            print("the element at \(index) is \(value)")
            if index % 2 == 1 {
                tmp.append(value)
            }
        }
        return tmp
    }
}
