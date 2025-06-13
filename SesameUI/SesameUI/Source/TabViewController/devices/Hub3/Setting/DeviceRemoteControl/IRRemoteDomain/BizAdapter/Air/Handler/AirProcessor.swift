//
//  AirProcessor.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//



import Foundation
import UIKit
import SesameSDK
/**
 空调遥控器 指令处理
 */
class AirProcessor: IrInterface {
    private(set) var mPower: Int = 0x00
    private(set) var mTemperature: Int = 25
    private(set) var mWindRate: Int = 0x01 // 01 02 03 04
    private(set) var mWindDirection: Int = 0x02 // 01 02 03
    private(set) var mAutomaticWindDirection: Int = 0x01 // 00
    private(set) var mMode: Int = 0x01 // 0x01 ~ 0x05
    private(set) var mSleep: Int = 0x00
    private(set) var mHeat: Int = 0x00
    private(set) var mLight: Int = 0x01
    private(set) var mEco: Int = 0x00
    var mKey: Int = 0x01
    private(set) var mState: Int = 0x00
    private var arcTable: [[UInt]] = []
    
    // MARK: - Setup
    
    func setupTable() {
        guard let url = Bundle.main.url(forResource: "air_table", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let intArray = try? JSONDecoder().decode([[Int]].self, from: data) else {
            return
        }
        
        arcTable = intArray.map { row in
            row.map { UInt($0) }
        }
    }
    
    // MARK: - Temperature Methods
    
    func getTemp() -> UInt8 {
        L.d("AIR", "GetTemp: \(mTemperature)")
        return UInt8(mTemperature)
    }
    
    func setTemp(_ temp: UInt8) {
        mTemperature = Int(temp)
    }
    
    // MARK: - Wind Rate Methods
    
    func getWindRate() -> UInt8 {
        return UInt8(mWindRate)
    }
    
    func setWindRate(_ rate: UInt8) {
        mWindRate = Int(rate)
    }
    
    // MARK: - Wind Direction Methods
    
    func getWindDir() -> UInt8 {
        return UInt8(mWindDirection)
    }
    
    func setWindDir(_ dir: UInt8) {
        mWindDirection = Int(dir)
    }
    
    // MARK: - Auto Wind Direction Methods
    
    func getAutoWindDir() -> UInt8 {
        return UInt8(mAutomaticWindDirection)
    }
    
    func setAutoWindDir(_ dir: UInt8) {
        mAutomaticWindDirection = Int(dir)
    }
    
    // MARK: - Mode Methods
    
    func getMode() -> UInt8 {
        return UInt8(mMode)
    }
    
    func setMode(_ mode: UInt8) {
        mMode = Int(mode)
    }
    
    // MARK: - Power Methods
    
    func getPower() -> UInt8 {
        return UInt8(mPower)
    }
    
    func setPower(_ power: UInt8) {
        mPower = Int(power)
    }
    
    // MARK: - Sleep Methods
    
    func getSleep() -> UInt8 {
        return UInt8(mSleep)
    }
    
    func setSleep(_ sleep: UInt8) {
        mSleep = Int(sleep)
    }
    
    // MARK: - Heat Methods
    
    func getHeat() -> UInt8 {
        return UInt8(mHeat)
    }
    
    func setHeat(_ heat: UInt8) {
        mHeat = Int(heat)
    }
    
    // MARK: - Light Methods
    
    func getLight() -> UInt8 {
        return UInt8(mLight)
    }
    
    func setLight(_ light: UInt8) {
        mLight = Int(light)
    }
    
    // MARK: - Eco Methods
    
    func getEco() -> UInt8 {
        return UInt8(mEco)
    }
    
    func setEco(_ eco: UInt8) {
        mEco = Int(eco)
    }
    
    // MARK: - State Methods
    
    func setState(_ state: Int) {
        mState = state
    }
    
    func getState() -> UInt8 {
        return UInt8(mState)
    }
    
    func findType(typeIndex: Int, key: Int) throws -> Data {
        return Data(try IrAirTool.searchKeyData(
            type: IRType.DEVICE_REMOTE_AIR,
            arrayIndex: typeIndex,
            arcTable: arcTable
        ))
    }
    
    func findBrand(brandIndex: Int, key: Int) throws -> Data {
        return Data(try IrAirTool.searchKeyData(
            type: IRType.DEVICE_REMOTE_AIR,
            arrayIndex: brandIndex,
            arcTable: arcTable
        ))
    }
    
    func search(arrayIndex: Int) throws -> [UInt8] {
        var buf = try IrAirTool.searchKeyData(
            type: IRType.DEVICE_REMOTE_AIR,
            arrayIndex: arrayIndex,
            arcTable: arcTable
        )
        
        buf[4] = getTemp()
        L.d("search", "buf 4: \(buf.map { String(format: "%02X", $0) }.joined())")
        
        buf[5] = getWindRate()
        buf[6] = getWindDir()
        buf[7] = getAutoWindDir()
        buf[8] = getPower()
        buf[9] = UInt8(mKey)
        buf[10] = getMode()
        
        // 设置倒数第二个字节为 0xFF
        buf[buf.count - 2] = 0xFF
        
        // 计算校验和
        let checkSum = buf.dropLast(1).reduce(0) { $0 + Int($1) }
        buf[buf.count - 1] = UInt8(checkSum & 0xFF)
        
        return buf
    }
    
    func getStudyData(data: Data, len: Int) -> Data {
        return IrAirTool.studyKeyCode(data: data, len: len)
    }
    
    func getBrandArray(brandIndex: Int) -> [Int]? {
        return IrAirTool.getBrandArray(type: IRType.DEVICE_REMOTE_AIR, brandIndex: brandIndex)
    }
    
    func getTypeArray(typeIndex: Int) -> [Int]? {
        return IrAirTool.getTypeArray(type: IRType.DEVICE_REMOTE_AIR, typeIndex: typeIndex)
    }
    
    func getTypeCount(typeIndex: Int) -> Int {
        return IrAirTool.getTypeCount(type: IRType.DEVICE_REMOTE_AIR, typeIndex: typeIndex)
    }
    
    func getBrandCount(brandIndex: Int) -> Int {
        return IrAirTool.getBrandCount(type: IRType.DEVICE_REMOTE_AIR, brandIndex: brandIndex)
    }
    
    func getTableCount() -> Int {
        return IrAirTool.getTableCount(type: IRType.DEVICE_REMOTE_AIR)
    }
    
    // MARK: - Builder Methods
    
    @discardableResult
    func buildParamsWithPower(_ power: Int) -> AirProcessor {
        self.mPower = power
        return self
    }
    
    @discardableResult
    func buildParamsWithTemperature(_ temperature: Int) -> AirProcessor {
        self.mTemperature = temperature
        return self
    }
    
    @discardableResult
    func buildParamsWithModel(_ model: Int) -> AirProcessor {
        self.mMode = model
        return self
    }
    
    @discardableResult
    func buildParamsWithFanSpeed(_ windRate: Int) -> AirProcessor {
        self.mWindRate = windRate
        return self
    }
    
    @discardableResult
    func buildParamsWithWindDirection(_ windDirection: Int) -> AirProcessor {
        self.mWindDirection = windDirection
        return self
    }
    
    @discardableResult
    func buildParamsWithAutomaticWindDirection(_ automaticWindDirection: Int) -> AirProcessor {
        self.mAutomaticWindDirection = automaticWindDirection
        return self
    }
    
    // MARK: - Parse Methods
    
    func parseAirData(_ state: String) -> Bool {
        // 基本格式验证
        guard !state.isEmpty,
              state.range(of: "^[0-9A-Fa-f]+$", options: .regularExpression) != nil else {
            print("Error: Invalid input")
            return false
        }
        
        // 将十六进制字符串转换为字节数组
        let data = stride(from: 0, to: state.count, by: 2).compactMap { index in
            let startIndex = state.index(state.startIndex, offsetBy: index)
            let endIndex = state.index(startIndex, offsetBy: 2, limitedBy: state.endIndex) ?? state.endIndex
            let hexByte = String(state[startIndex..<endIndex])
            return UInt8(hexByte, radix: 16)
        }
        
        guard data.count > 10 else { return false }
        
        do {
            mTemperature = Int(data[4])
            mWindRate = Int(data[5])
            mWindDirection = Int(data[6])
            mAutomaticWindDirection = Int(data[7])
            mPower = Int(data[8])
            mMode = Int(data[10])
            
            L.d("parseAirData", """
                mTemperature: \(mTemperature), 
                mWindRate: \(mWindRate), 
                mWindDirection: \(mWindDirection), 
                mAutomaticWindDirection: \(mAutomaticWindDirection), 
                mPower: \(mPower), 
                mMode: \(mMode)
                """)
            return true
        } catch {
            print("Error parsing air data: \(error)")
            return false
        }
    }
}

