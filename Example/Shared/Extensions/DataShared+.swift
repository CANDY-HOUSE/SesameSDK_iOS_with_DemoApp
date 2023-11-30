//
//  Data+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Data {
    init(hex: String) {
        self.init(Array<UInt8>(hex: hex))
    }

    var bytes: Array<UInt8> {
        return Array(self)
    }

    public func toHexString() -> String {
        return bytes.toHexString()
    }

    private func unpackValue<T: FixedWidthInteger>() -> T {
        return self.withUnsafeBytes {
            return $0.baseAddress!.assumingMemoryBound(to: T.self).withMemoryRebound(to: T.self, capacity: 0) {
                return $0.pointee
            }
        }
    }

    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    var uint16: UInt16 {
        return self.unpackValue()
    }

    var uint8: UInt8 {
        return self.unpackValue()
    }

    var uint32: UInt32 {
        return self.unpackValue()
    }

    func getValue<T>(offset: Int, initialValue: T) -> T? {

        var data: T     = initialValue
        let itemSize    = MemoryLayout.size(ofValue: data)

        let maxOffset = count - itemSize
        guard Range(0...maxOffset).contains(offset) else {
            return nil
        }

        let nsdata = self as NSData

        nsdata.getBytes(&data, range: NSRange(location: offset, length: itemSize))

        return data
    }
}
