//
//  Array+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Array {
    init(reserveCapacity: Int) {
        self = []
        self.reserveCapacity(reserveCapacity)
    }

    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

public extension Array where Element == Int {
    func toHexString() -> String {
        let hexStrings = self.map { String(format: "%02X", $0) }
        return hexStrings.joined(separator: "")
    }
    
    func toData() -> Data {
        var data = Data()
        for value in self {
            if value < 0 || value > UInt16.max {
                print("Warning: \(value) is out of UInt16 range. It will be skipped.")
                continue
            }
            if value <= UInt8.max {
                data.append(UInt8(value))
            } else {
                let lowerByte = UInt8(value & 0xFF)
                let upperByte = UInt8((value >> 8) & 0xFF)
                data.append(contentsOf: [lowerByte, upperByte])
            }
        }
        return data
    }
}

public extension Array where Element == UInt8 {
    init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }

    func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }

    func toBase64() -> String? {
        return Data( self).base64EncodedString()
    }

    init(base64: String) {
        self.init()

        guard let decodedData = Data(base64Encoded: base64) else {
            return
        }

        append(contentsOf: decodedData.bytes)
    }
}
