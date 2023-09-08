//
//  Data+.swift
//  sesame2-sdk
//
//  Created by tse on 2019/8/6.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

// swiftlint:disable identifier_name

import Foundation

extension Dictionary {
    mutating func getOrPut(_ key: Key, backup: Value) -> Value {
        if let stored = self[key] {
            return stored
        } else {
            self[key] = backup
            return backup
        }
    }
}
extension Data {
    static func generateRandomData(count: Int) -> Data {
        var data = Data(count: count)
        let ret = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        if ret == errSecSuccess {
            return data
        } else {
            return Data.generateRandomData(count: count)
        }
    }

    static func createHistag(_ keyData: Data?) ->Data{
        var tagCount_hisTag = Data()
        let histag = keyData ?? Data()
        let tagCount = histag.count
        let ss = 22 - tagCount  - 1// -1 for tagCount need onebyte
        tagCount_hisTag = UInt8(tagCount).data + histag + Data(count: ss)
        return tagCount_hisTag
    }
    static func createOS2Histag(_ keyData: Data?) ->Data{
        var histag = keyData ?? Data()
        L.d("標籤,Data+", histag.toHexString(), histag.count)
        if histag.count > 29 {
            histag = histag.subdata(in: 0..<30)
        } // 根据server解析协议，不能超过30以区分来源
//        L.d("hcia", "[histag]: \(histag.count)")
        return UInt8(histag.count).data + histag
    }

    
    mutating func toInt8() -> Int8 {
        var enabledBefore: Int8 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    
    mutating func toUInt8() -> UInt8 {
        var enabledBefore: UInt8 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    
    mutating func toInt16() -> Int16{
        var enabledBefore: Int16 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    
    func toUInt16() -> UInt16{
        var enabledBefore: UInt16 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    
    mutating func toInt32() -> Int32{
        var enabledBefore: Int32 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    func toUInt32() -> UInt32{
        var enabledBefore: UInt32 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
    
    func toUInt64() -> UInt64 {
        var enabledBefore: UInt64 = 0
        let _ = Swift.withUnsafeMutableBytes(of: &enabledBefore, { self.copyBytes(to: $0)} )
        return enabledBefore
    }
}

extension String {
    //    func fromBase64() -> Data? {
    //
    //        guard let data = Data(base64Encoded: self) else {
    //            return nil
    //        }
    //
    //        return data
    //    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

    func toUUID() -> UUID? {
        return UUID(uuidString: self)
    }

    var bytes: [UInt8] {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    func noDashtoUUID() -> UUID? {
        var input = self
        input.insert("-", at: input.index(input.startIndex, offsetBy: 20))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 16))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 12))
        input.insert("-", at: input.index(input.startIndex, offsetBy: 8))
        return UUID(uuidString: input)
    }
    
    func remove(_ char: String) -> String {
        replacingOccurrences(of: char, with: "")
    }
    
    func first(_ index: Int) -> String {
        let endIndex = self.index(startIndex, offsetBy: index)
        return String(self[..<endIndex])
    }
    func hexStringtoData() -> Data {
        return Data(hex: self)
    }

    //sesame2 ID 生成 bleID規則。uuid -> nohashStr -> hextodata-> 前五個byte
    func sesame2IDtoBleIDData() -> Data {
        let input = self
        let bleidData =  input.remove("-").first(10).hexStringtoData()
        return bleidData
    }
}

extension Array {
    init(reserveCapacity: Int) {
        self = []
        self.reserveCapacity(reserveCapacity)
    }

    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

extension Array where Element == UInt8 {
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

    func toBase64() -> String {
        return Data(self).base64EncodedString()
    }

    init(base64: String) {
        self.init()

        guard let decodedData = Data(base64Encoded: base64) else {
            return
        }

        append(contentsOf: decodedData.bytes)
    }
}


extension Data {
    init(hex: String) {
        self.init([UInt8](hex: hex))
    }

    var copyData: Data {
        return Data(Array(self))
    }

    var bytes: [UInt8] {
        return Array(self)
    }

    func toCutedHistag() -> Data? {
//        let histag = content
        let tagcount_historyTag = self
        let tagcount = UInt8(tagcount_historyTag[0])
        var historyTag:Data?

        if tagcount == 0 { 
            historyTag = nil
        } else {
            historyTag = tagcount_historyTag[safeBound: 1...Int(tagcount)]
        }
        return historyTag
    }
    func toHexString() -> String {
        return bytes.toHexString()
    }
    func toHexLog() -> String {
        return "\(bytes.toHexString()) [\(self.count)]"
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

    //    func hexEncodedString(options: HexEncodingOptions = []) -> String {
    //        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
    //        return map { String(format: format, $0) }.joined()
    //    }

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

    func decodeJsonDictionary() throws -> Any {
        return try JSONSerialization.jsonObject(with: self, options: .mutableContainers)
    }
    
    subscript(safeBound safeBound: ClosedRange<Int>) -> Data? {
        let copySelf = self.copyData
        guard safeBound.upperBound < copySelf.count else {
            return nil
        }
        let dataArray = Array(copySelf)
        let dataChunk = dataArray[safeBound.lowerBound...safeBound.upperBound]
        return Data(dataChunk)
    }
    
    //    subscript(safeBound safeBound: PartialRangeFrom<Int>) -> Data? {
    //        let copySelf = self.copyData
    //        guard safeBound.lowerBound < copySelf.count else {
    //            return nil
    //        }
    //        let dataArray = Array(copySelf)
    //        let dataChunk = dataArray[safeBound]
    //        return Data(dataChunk)
    //    }
}

extension UInt8 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)
    }
}

extension Int32 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Int32>.size)
    }
}

extension Int16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Int16>.size)
    }
}

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension UnicodeScalar {
    var hexNibble: UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        } else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        } else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}

extension UInt32 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }

    var byteArrayLittleEndian: [UInt8] {
        return [
            UInt8((self & 0xFF000000) >> 24),
            UInt8((self & 0x00FF0000) >> 16),
            UInt8((self & 0x0000FF00) >> 8),
            UInt8(self & 0x000000FF)
        ]
    }
}

extension URL {
    static var chURL: URL {
        URL(string: "candyhouse://Sesame2SDK/")!
    }
    
    func queryItemAdded(name: String,  value: String?) -> URL? {
        return self.queryItemsAdded([URLQueryItem(name: name, value: value)])
    }
    
    func getQuery(name:String) -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let query = components?.queryItems?.filter({
            return $0.name == name
        })
        return query?.first?.value ?? "NOdata"

    }
    
    func queryItemsAdded(_ queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: nil != self.baseURL) else {
            return nil
        }
        components.queryItems = queryItems + (components.queryItems ?? [])
        return components.url
    }
    
}

extension Data {
    func divideArray(chunkSize: Int) -> [Data] {
        var result: [Data] = []
        var currentPosition = 0

        while currentPosition < self.count {
            let nextPosition = Swift.min(currentPosition + chunkSize, self.count)
            let subdata = self.subdata(in: currentPosition..<nextPosition)
            result.append(subdata)
            
            currentPosition = nextPosition
        }

        return result
    }
}
