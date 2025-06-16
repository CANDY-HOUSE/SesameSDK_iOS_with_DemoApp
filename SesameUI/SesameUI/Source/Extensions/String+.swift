//
//  String+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation

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
    
    func toDictioinary() -> [String: String]? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                return jsonResult
            } else {
                print("Data couldn't be converted to [String: String]")
                return nil
            }
        } catch {
            print("Error parsing JSON string: \(error)")
            return nil
        }
    }
}

extension Dictionary {
    func toJSONString() -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting dict to JSON string: \(error)")
            return nil
        }
    }
}
