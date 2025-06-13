//
//  IRRemoteControl.swift
//  SesameUI
//
//  Created by eddy on 2024/1/27.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

protocol UninKeyConvertor {
    associatedtype T
    var text: String { get set }
    var imageName: String? { get set }
    var rawKey: T? { get }
}

extension UninKeyConvertor {
    var fromattedText: NSAttributedString {
        return NSAttributedString(string: text)
    }
}

struct KeyModel<T>: UninKeyConvertor {
    typealias T = T
    var text: String
    var imageName: String?
    var rawKey: T?
    init(text: String, imageName: String? = nil, rawKey: T? = nil) {
        self.text = text
        self.imageName = imageName
        self.rawKey = rawKey
    }
}

protocol UniversalRemoteBehavior: AnyObject {
    var  xmlConfPathAndName: (fileName: String, eleAttName: String) { get }
    func generate(_ completion: @escaping () -> Void)
    
    var  funcKeys: [any UninKeyConvertor] { get }
    func sendCommand(_ data: Data, _ device: CHHub3)
}

extension UniversalRemoteBehavior {
    func fetchFuncKeys(result: @escaping ([any UninKeyConvertor]) -> Void) {
        let fileTuple = xmlConfPathAndName
        XMLParseHandler.fetchXMLContent(fileName: fileTuple.fileName, eleAttrName: fileTuple.eleAttName) { contentModels in
            let keyModels = contentModels.map { it in
                return KeyModel(text:it.plainText, rawKey: it)
            }
            result(keyModels)
        }
    }
}

protocol IR {
    func findType(typeIndex: Int, key: Int) -> [UInt8]?
    func findBrand(brandIndex: Int, key: Int) -> [UInt8]?
    func search(arrayIndex: Int, key: Int) -> [Int]
    func getStudyData(data: [UInt8], len: Int) -> [UInt8]?
    func getBrandArray(brandIndex: Int) -> [Int]
    func getTypeArray(typeIndex: Int) -> [Int]
    func getTypeCount(typeIndex: Int) -> Int
    func getBrandCount(brandIndex: Int) -> Int
    func getTableCount() -> Int
}

final class ETIR {

    private init() {}
    
    // Builder 函数，返回 IR 类型的实例
    static func builder(type: Int) -> IR? {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_AIR: return Air()
        default:
            return nil
        }
        return nil
    }
    
    static func Init() {
        // 调用实际的初始化代码，可能是 C 或 C++ 代码
    }
    
    static func studyKeyCode(data: [UInt8], len: Int) -> [UInt8]? {
        return nil
    }
    
    static func decimalToTwoHexInts(_ number: Int) -> [UInt8] {
        let firstPart = number / (0xff + 1)
        let secondPart = number % (0xff + 1)
        return [UInt8(firstPart), UInt8(secondPart)]
    }
    
    static let AirPrefixCode: [UInt8] = [0x30, 0x01]
    static let NonAirPrefixCode: [UInt8] = [0x30, 0x00]
    static func searchKeyData(type: Int, arrayIndex: Int, key: Int) -> [UInt8]? {
        var buf = [UInt8]()
        if type == IRDeviceType.DEVICE_REMOTE_AIR {
            let MaxIndex = arcTable.count - 1
            let searchIndex = min(arrayIndex, MaxIndex)
            buf.append(contentsOf: AirPrefixCode)
            buf.append(contentsOf: decimalToTwoHexInts(arrayIndex))
            buf.append(contentsOf: Array(repeating: 0, count: 7))
            var indexsets = arcTable[searchIndex]
            indexsets[0] = indexsets[0] + 1
            buf.append(contentsOf: indexsets.map{ UInt8($0) })
            buf.append(0xff)
            buf.append(0)
        } else {
            buf.append(contentsOf: NonAirPrefixCode)
        }
        return buf
    }
    
    static func getTableCount(type: Int) -> Int {
        // 对应的实际实现
        return 0
    }
    
    static func getBrandCount(type: Int, brandIndex: Int) -> Int {
        return 0
    }
    
    static func getTypeCount(type: Int, typeIndex: Int) -> Int {
        return 0
    }
    
    static func getBrandArray(type: Int, brandIndex: Int) -> [Int] {
        return []
    }
    
    static func getTypeArray(type: Int, typeIndex: Int) -> [Int] {
        if type == IRDeviceType.DEVICE_REMOTE_AIR {
            return [typeIndex]
        }
        return []
    }
    
    static func getAirDelay(row: Int, col: Int) -> Int {
        return 0
    }
}
