//
//  IrAirTool.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import UIKit
import SesameSDK

class IrAirTool {
    // MARK: - Constants
    private static let AirPrefixCode: [UInt8] = [0x30, 0x01]
    private static let NonAirPrefixCode: [UInt8] = [0x30, 0x00]
    
    // MARK: - Static Methods
    
    static func builder(type: Int) -> IrInterface? {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_AIR:
            return AirProcessor()
        default:
            return nil
        }
    }
    
    static func studyKeyCode(data: Data, len: Int) -> Data {
        return Data()
    }
    
    static func decimalToTwoHexInts(_ number: Int) -> [UInt8] {
        let firstPart = number / (0xff + 1)
        let secondPart = number % (0xff + 1)
        return [UInt8(firstPart), UInt8(secondPart)]
    }
    
    static func searchKeyData(type: Int, arrayIndex: Int, arcTable: [[UInt]]) throws -> [UInt8] {
        var buf = [UInt8]()
        
        if type == IRDeviceType.DEVICE_REMOTE_AIR {
            let maxIndex = arcTable.count - 1
            let searchIndex = min(arrayIndex, maxIndex)
            
            L.d("searchKeyData", "arrayIndex: \(arrayIndex), searchIndex: \(searchIndex)")
            
            buf.append(contentsOf: AirPrefixCode)
            buf.append(contentsOf: decimalToTwoHexInts(arrayIndex))
            buf.append(contentsOf: Array(repeating: 0, count: 7))
            
            var indexsets = arcTable[searchIndex]
            indexsets[0] += 1
            buf.append(contentsOf: indexsets.map { UInt8($0) })
            
            buf.append(0xFF)
            buf.append(0)
            
            L.d("searchKeyData", "buf: \(buf.map { String(format: "%02X", $0) }.joined())")
        } else {
            buf.append(contentsOf: NonAirPrefixCode)
        }
        
        return buf
    }
    
    // MARK: - Table Related Methods
    
    static func getTableCount(type: Int) -> Int {
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
        return type == IRDeviceType.DEVICE_REMOTE_AIR ? [typeIndex] : []
    }
    
    // MARK: - Filter Methods
    
    static func filterIrRemotesByCode(remotes: [IRRemote], airSupport: [[Int]]) -> [IRRemote] {
        let result = remotes.filter { remote in
            airSupport.contains { array in
                Array(array[1...]).contains(remote.code)
            }
        }
        
        L.d("filterIrRemotesByCode", "result: \(result.count) remotes: \(remotes.count)")
        return result
    }
    
    static func filterIrRemotesByMode(remotes: [IRRemote], airSupport: [String]) -> [IRRemote] {
        var matchCounts: [String: Int] = [:]
        
        let result = remotes.filter { remote in
            airSupport.contains { item in
                let model = remote.model.lowercased()
                guard !model.isEmpty else { return false }
                let isMatch = model.contains(item.lowercased()) || item.lowercased().contains(model)
                
                if isMatch {
                    matchCounts[item, default: 0] += 1
                }
                
                return isMatch
            }
        }
        
        // 日志输出
        L.d("filterIrRemotesByMode",
            "总过滤结果 - 过滤后: \(result.count), 过滤前: \(remotes.count)")
        
        matchCounts.forEach { model, count in
            L.d("filterIrRemotesByMode", "匹配型号: \(model), 匹配数量: \(count)")
        }
        
        let unmatchedModels = airSupport.filter { !matchCounts.keys.contains($0) }
        if !unmatchedModels.isEmpty {
            L.d("filterIrRemotesByMode",
                "未匹配的支持型号: \(unmatchedModels.joined(separator: ", "))")
        }
        
        return result
    }
}
