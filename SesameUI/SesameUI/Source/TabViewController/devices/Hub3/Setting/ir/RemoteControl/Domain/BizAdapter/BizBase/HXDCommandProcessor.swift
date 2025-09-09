//
//  HXDCommandProcessor.swift
//  SesameUI
//
//  Created by wuying on 2025/9/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import SesameSDK

class HXDCommandProcessor {
    private let tag = String(describing: HXDCommandProcessor.self)
    private var power: Int = 0x00
    private var temperature: Int = 25
    private var fanSpeed: Int = 0x01
    private var windDirection: Int = 0x02
    private var autoWindDirection: Int = 0x01
    private var mode: Int = 0x02
    private var key: Int = 0x01
    private var code: Int = 0x00
    private var defaultTable: [UInt] = [0, 0, 0]
    private let airPrefixCode: [UInt8] = [0x30, 0x01]
    private let commonPrefixCode: [UInt8] = [0x30, 0x00]
    
    func buildAirCommand() -> [UInt8] {
        var buf = buildKeyData(prefixCodeArray: airPrefixCode, code: code, table: defaultTable)
        buf[4] = UInt8(temperature)
        buf[5] = UInt8(fanSpeed)
        buf[6] = UInt8(windDirection)
        buf[7] = UInt8(autoWindDirection)
        buf[8] = UInt8(power)
        buf[9] = UInt8(key)
        buf[10] = UInt8(mode)
        buf[buf.count - 2] = 0xFF
        
        let checkSum = buf.dropLast(1).reduce(0) { $0 + Int($1) }
        buf[buf.count - 1] = UInt8(checkSum & 0xFF)
        
        let hexString = buf.map { String(format: "%02X", $0) }.joined()
        L.d(tag,"buildAirCommand: \(hexString)")
        return buf
    }
    
    func buildNoneAirCommand() -> [UInt8] {
        var buf = buildKeyData(prefixCodeArray: commonPrefixCode, code: code, table: defaultTable)
        buf[9] = UInt8(key)
        buf[buf.count - 2] = 0xFF
        
        let checkSum = buf.dropLast(1).reduce(0) { $0 + Int($1) }
        buf[buf.count - 1] = UInt8(checkSum & 0xFF)
        
        let hexString = buf.map { String(format: "%02X", $0) }.joined()
        L.d(tag,"buildCommonCommand: \(hexString)")
        return buf
    }
    
    func buildKeyData(prefixCodeArray: [UInt8], code: Int, table: [UInt]) -> [UInt8] {
        var indexTable = table
        var buf: [UInt8] = []
        
        // 添加前缀代码
        buf.append(contentsOf: prefixCodeArray)
        
        // 添加转换后的代码
        let codeBytes = decimalToTwoHexInts(number: code)
        buf.append(contentsOf: codeBytes)
        
        // 添加7个零字节
        buf.append(contentsOf: Array(repeating: 0, count: 7))
        
        // 更新索引表
        indexTable[0] = table[0] + 1
        
        // 添加索引表
        buf.append(contentsOf: indexTable.map { UInt8($0) })
        
        // 添加结束标记
        buf.append(0xFF)
        buf.append(0)
        
        return buf
    }
    
    func decimalToTwoHexInts(number: Int) -> [UInt8] {
        let firstPart = number / (0xFF + 1)
        let secondPart = number % (0xFF + 1)
        return [UInt8(firstPart), UInt8(secondPart)]
    }
    
    // MARK: - Setter/Getter Methods
    
    @discardableResult
    func setPower(_ power: Int) -> HXDCommandProcessor {
        self.power = power
        return self
    }
    
    func getPower() -> Int {
        return power
    }
    
    @discardableResult
    func setTemperature(_ temperature: Int) -> HXDCommandProcessor {
        self.temperature = temperature
        return self
    }
    
    func getTemperature() -> Int {
        return temperature
    }
    
    @discardableResult
    func setMode(_ mode: Int) -> HXDCommandProcessor {
        self.mode = mode
        return self
    }
    
    func getMode() -> Int {
        return mode
    }
    
    @discardableResult
    func setFanSpeed(_ windRate: Int) -> HXDCommandProcessor {
        self.fanSpeed = windRate
        return self
    }
    
    func getFanSpeed() -> Int {
        return fanSpeed
    }
    
    @discardableResult
    func setWindDirection(_ windDirection: Int) -> HXDCommandProcessor {
        self.windDirection = windDirection
        return self
    }
    
    func getWindDirection() -> Int {
        return windDirection
    }
    
    @discardableResult
    func setAutoWindDirection(_ autoWindDirection: Int) -> HXDCommandProcessor {
        self.autoWindDirection = autoWindDirection
        return self
    }
    
    func getAutoDirection() -> Int {
        return autoWindDirection
    }
    
    @discardableResult
    func setKey(_ key: Int) -> HXDCommandProcessor {
        self.key = key
        return self
    }
    
    func getKey() -> Int {
        return key
    }
    
    @discardableResult
    func setCode(_ code: Int) -> HXDCommandProcessor {
        self.code = code
        return self
    }
    
    func getCode() -> Int {
        return code
    }
    
    func parseAirData(state: String) -> Bool {
        if state.isEmpty {
            L.e(tag,"Error: Empty input")
            return false
        }
        
        // 检查是否只包含十六进制字符
        let hexPattern = "^[0-9A-Fa-f]+$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: state.count)
        if regex?.firstMatch(in: state, options: [], range: range) == nil {
            L.e(tag,"Error: Invalid hex characters in input")
            return false
        }
        
        // 将十六进制字符串转换为字节数组
        var data: [UInt8] = []
        var index = state.startIndex
        while index < state.endIndex {
            let nextIndex = state.index(index, offsetBy: 2, limitedBy: state.endIndex) ?? state.endIndex
            let hexString = String(state[index..<nextIndex])
            if let byte = UInt8(hexString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        
        if data.count <= 10 {
            return false
        }
        
        do {
            temperature = Int(data[4])
            fanSpeed = Int(data[5])
            windDirection = Int(data[6])
            autoWindDirection = Int(data[7])
            power = Int(data[8])
            mode = Int(data[10])
            
            L.d(tag,"parseAirData - temperature: \(temperature), windRate: \(fanSpeed), windDirection: \(windDirection), automaticWindDirection: \(autoWindDirection), power: \(power), mode: \(mode)")
            return true
        } catch {
            L.d(tag,"Error parsing data: \(error)")
        }
        
        return false
    }
}
