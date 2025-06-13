//
//  irAirRemoteControl.swift
//  SesameUI
//
//  Created by eddy on 2024/5/30.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import UIKit

private let AIR_TEMPERATURE = -1
class ControlAirRemote: NSObject, UniversalRemoteBehavior {
    var xmlConfPathAndName: (fileName: String, eleAttName: String) {
        return (fileName: "strings", eleAttName: "strs_air_key")
    }
    var funcKeys: [any UninKeyConvertor] = []
    var air = ETIR.builder(type: IRDeviceType.DEVICE_REMOTE_AIR) as! Air
    private var viewReloadHandler: () -> Void = {}
    public private(set) var defaultState: String?
    private var typeCode = 0
    private lazy var keyStateTextOptions = {
        return [
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_MODE: makeLocalizedStateText(prefix: "co.candyhouse.airKey.mode", range: 0x01...0x05),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_RATE: makeLocalizedStateText(prefix: "co.candyhouse.airKey.windRate", range: 0x01...0x04),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_DIRECTION: makeLocalizedStateText(prefix: "co.candyhouse.airKey.windDir", range: 0x01...0x03),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_AUTOMATIC_WIND_DIRECTION: makeLocalizedStateText(prefix: "co.candyhouse.airKey.windAutoDir", range: 0x01...0x02)
        ]
    }()
    private lazy var keyStateImgOptions = {
        return [
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_POWER: makeImageStateText(prefix: "air_power_", range: 0x00...0x01),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_IN: [0x00: "air_temp_in"],
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_OUT: [0x00: "air_temp_out"],
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_MODE: makeImageStateText(prefix: "air_mode_icon_", range: 0x01...0x05),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_RATE: makeImageStateText(prefix: "air_wind_rate_", range: 0x01...0x04),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_DIRECTION: makeImageStateText(prefix: "air_direction_", range: 0x01...0x03),
            IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_AUTOMATIC_WIND_DIRECTION: makeImageStateText(prefix: "air_auto_dir_", range: 0x01...0x02)
        ]
    }()
    
    private func makeLocalizedStateText(prefix: String, range: ClosedRange<Int>) -> [Int: String] {
        return Dictionary(uniqueKeysWithValues: range.map { ($0, "\(prefix)\($0)".localized) })
    }
    
    private func makeImageStateText(prefix: String, range: ClosedRange<Int>) -> [Int: String] {
        return Dictionary(uniqueKeysWithValues: range.map { ($0, "\(prefix)\($0)") })
    }
    
    init(_ state: String?) {
        super.init()
        self.defaultState = state
        prepareHapticFeedback()
    }
    
    deinit {
        L.d("ControlAirRemote deinit")
    }
    
    func setAirData(typeCode: Int) {
        self.typeCode = typeCode
    }
    
    func parseState(_ state: String?) {
        guard let state = state, state.count > 22 else {
            viewReloadHandler()
            return
        }
        let deviceType = Int(state.substring(with: 0..<4), radix: 16)!
        guard deviceType == 0x3001 else { return }
        let deviceModel = Int(state.substring(with: 4..<8), radix: 16)!
        let temp = Int(state.substring(with: 8..<10), radix: 16)!
        let windRate = Int(state.substring(with: 10..<12), radix: 16)!
        let windDirection = Int(state.substring(with: 12..<14), radix: 16)!
        let windAutoDirection = Int(state.substring(with: 14..<16), radix: 16)!
        let power = Int(state.substring(with: 16..<18), radix: 16)!
        let key = Int(state.substring(with: 18..<20), radix: 16)!
        let mode = Int(state.substring(with: 20..<22), radix: 16)!
        
        self.typeCode = deviceModel
        air.mTemperature = temp
        air.mWindRate = windRate
        air.mWindDirection = windDirection
        air.mAutomaticWindDirection = windAutoDirection
        air.mPower = power
        air.mKey = key
        air.mMode = mode
        
        applyState()
    }
    
    func applyState() {
        guard funcKeys.isEmpty == false else {
            viewReloadHandler()
            return
        }
        let dataSource = Array(funcKeys)
        for (index, it) in dataSource.enumerated() {
            guard let option = it.rawKey as? ContentModel, let codeId = Int(option.code) else { continue  }
            switch codeId {
            case AIR_TEMPERATURE: 
                funcKeys[index].text = "\(String(air.mTemperature))°C"
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_POWER:
                let stateOff = 0x00
                funcKeys[index].imageName = keyStateImgOptions[codeId]![stateOff]
                let isOnPosition = air.mPower != stateOff
                funcKeys[isOnPosition ? 0 : 2].imageName = keyStateImgOptions[codeId]![0x01]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_IN:
                funcKeys[index].imageName = keyStateImgOptions[codeId]![0x00]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_OUT:
                funcKeys[index].imageName = keyStateImgOptions[codeId]![0x00]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_MODE:
                funcKeys[index].text = keyStateTextOptions[codeId]![air.mMode]!
                funcKeys[index].imageName = keyStateImgOptions[codeId]![air.mMode]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_RATE:
                funcKeys[index].text = keyStateTextOptions[codeId]![air.mWindRate]!
                funcKeys[index].imageName = keyStateImgOptions[codeId]![air.mWindRate]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_DIRECTION:
                funcKeys[index].text = keyStateTextOptions[codeId]![air.mWindDirection]!
                funcKeys[index].imageName = keyStateImgOptions[codeId]![air.mWindDirection]
            case IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_AUTOMATIC_WIND_DIRECTION:
                funcKeys[index].text = keyStateTextOptions[codeId]![air.mAutomaticWindDirection + 1]!
                funcKeys[index].imageName = keyStateImgOptions[codeId]![air.mAutomaticWindDirection + 1]
            default: break
            }
        }
        viewReloadHandler()
    }
    
    func generate(_ completion: @escaping () -> Void) {
        viewReloadHandler = completion
        fetchFuncKeys { [weak self] keys in
            guard let self = self else { return }
            self.funcKeys = keys
            if (self.defaultState == nil) {
                self.defaultState = buildCommandData(2).toHexString()
            }
            self.parseState(self.defaultState)
        }
    }
    
    func sendCommand(_ data: Data, _ chDevice: CHHub3) {
        let hxdCodeStr = data.toHexString().uppercased()
        chDevice.irCodeEmit(id: hxdCodeStr, irDeviceUUID: "") { _ in }
        applyState()
        triggerHapticFeedback()
//        device.update(db: SesameIRStore.instance)
//        CHBluetoothCenter.shared.write(data: data, length: data.count)
    }
    
    // MARK: functions
    func buildCommandData(_ keyIndex: Int) -> Data {
        guard funcKeys.isEmpty == false, 
                let model = funcKeys[keyIndex].rawKey as? ContentModel,
              Int(model.code) != -1 else { return Data() }
        if Int(model.code) == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_POWER {
            air.mPower = keyIndex == 0 ? 0x00 : 0x01
        }
        return air.search(arrayIndex: typeCode, key: Int(model.code)!).toData()
    }
    
    
    /// –  创建自动匹配的键值
    /// - 在匹配按键测试前，需要先指定空调参数
    func setMatchParam(isPower: Bool,model:Int,temperature:Int,windRate:Int) {
        // power: 01 开机; 00 关机
        // model: 模式
        // temperature: 温度值
        // windRate: 风量
        air.mPower = isPower ? 0x01: 0x00
        air.mMode = model
        air.mWindRate = windRate
        air.mTemperature = temperature
        
    }
    func sendMatchCommandData(typeCode:Int,key:Int, chDevice: CHHub3){
        L.d("ControlAirRemote","buildMatchCommandData typeCode=\(typeCode)  key=\(key)")
        let data = air.search(arrayIndex: typeCode, key: key).toData()
        let hxdCodeStr = data.toHexString().uppercased()
        chDevice.irCodeEmit(id: hxdCodeStr, irDeviceUUID: "") { _ in }
    }
}

class Air: NSObject {
    var mPower: Int = 0x00
    var mTemperature: Int = 25
    var mWindRate: Int = 0x01 // 01 02 03 04
    var mWindDirection: Int = 0x02 // 01 02 03
    var mAutomaticWindDirection: Int = 0x01 // 00
    var mMode: Int = 0x01 // 0x01 ~ 0x05
    var mSleep: Int = 0x00
    var mHeat: Int = 0x00
    var mLight: Int = 0x01
    var mEco: Int = 0x00
    var mKey: Int = 0x01
    var mState: Int = 0x00

    func setKey(_ key: Int) {
        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_POWER {
            if mState == 0x00 {
                mPower = mPower == 0x00 ? 0x01 : 0x00
            } else {
                mPower = 0x01
            }
            mKey = 0x01
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_MODE {
            if mMode == 0x05 {
                mMode = 0x01
            } else {
                mMode += 1
            }
            mKey = 0x02
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_IN {
            if mMode == 2 || mMode == 5 {
                if mTemperature < 31 {
                    mTemperature += 1
                } else {
                    mTemperature = 31
                }
            }
            mKey = 0x06
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_TEMPERATURE_OUT {
            if mMode == 2 || mMode == 5 {
                if mTemperature > 17 {
                    mTemperature -= 1
                } else {
                    mTemperature = 17
                }
            }
            mKey = 0x07
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_AUTOMATIC_WIND_DIRECTION {
            mAutomaticWindDirection = mAutomaticWindDirection == 0x01 ? 0x00 : 0x01
            mKey = 0x05
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_RATE {
            if mWindRate >= 0x04 {
                mWindRate = 0x01
            } else {
                mWindRate += 1
            }
            mKey = 0x03
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_WIND_DIRECTION {
            if mWindDirection >= 0x03 {
                mWindDirection = 0x01
            } else {
                mWindDirection += 1
            }
            mAutomaticWindDirection = 0x00
            mKey = 0x04
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_SLEEP {
            mSleep = mSleep == 0x00 ? 0x01 : 0x00
            mKey = 0x08
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_HEAT {
            mHeat = mHeat == 0x00 ? 0x01 : 0x00
            mKey = 0x09
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_LIGHT {
            mLight = mLight == 0x01 ? 0x00 : 0x01
            mKey = 0x0a
        }

        if key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_ECO {
            mEco = mEco == 0x00 ? 0x01 : 0x00
            mKey = 0x0b
        }
        
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_COOL) {
            mMode = 0x02;
            mTemperature = 26;
            mPower = 0x01;
            mKey = 0x13;//mKey = 0x0c;
        }
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_HOT) {
                mTemperature = 27;
                mMode = 0x05;
                mPower = 0x01;
                mKey = 0x0d;
        }
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_MUTE) {
            if (mMode == 0x02){
                mMode = 0x02;
                mAutomaticWindDirection = 0x00;
                mWindDirection = 0x01;
                mWindRate = 0x02;
                mTemperature = 0x19;
                mPower = 0x01;
            }
            else if (mMode == 0x05){
                mMode = 0x05;
                mAutomaticWindDirection = 0x00;
                mWindDirection = 0x01;
                mWindRate = 0x02;
                mTemperature = 0x13;
                mPower = 0x01;
            }
            mKey = 0x0e;
            
        }
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_STRONG) {
            if (mMode == 0x02){
                mMode = 0x02;
                mAutomaticWindDirection = 0x00;
                mWindDirection = 0x03;
                mWindRate = 0x04;
                mTemperature = 18;
                mPower = 0x01;
//                mSleep = 0x00;
//                mEco = 0x00;
            }
            else if(mMode == 0x05){
                mMode = 0x05;
                mAutomaticWindDirection = 0x00;
                mWindDirection = 0x03;
                mWindRate = 0x04;
                mTemperature = 30;
                mPower = 0x01;
//                mSleep = 0x00;
//                mEco = 0x00;
            }
            mKey = 0x0f;
        }
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_XX) {
            mKey = 0x11;
        }
        if (key == IRDeviceType.REMOTE_KEY_AIR.KEY_AIR_YY) {
            mKey = 0x10;
        }
    }
}

extension Air: IR {
    func findType(typeIndex: Int, key: Int) -> [UInt8]? {
        return ETIR.searchKeyData(type: IRDeviceType.DEVICE_REMOTE_AIR, arrayIndex: typeIndex, key: key)
    }
    
    func findBrand(brandIndex: Int, key: Int) -> [UInt8]? {
        return ETIR.searchKeyData(type: IRDeviceType.DEVICE_REMOTE_AIR, arrayIndex: brandIndex, key: key)
    }
    
    func search(arrayIndex: Int, key: Int) -> [Int] {
        setKey(key)
        let bufData = ETIR.searchKeyData(type: IRDeviceType.DEVICE_REMOTE_AIR, arrayIndex: arrayIndex, key: key)
        var buf = bufData!.map { Int($0) }
        buf[4] = mTemperature
        buf[5] = mWindRate
        buf[6] = mWindDirection
        buf[7] = mAutomaticWindDirection
        buf[8] = mPower
        buf[9] = mKey
        buf[10] = mMode
        // 暂时屏蔽
//        buf[11] = mSleep
//        buf[12] = mHeat
//        buf[13] = mLight
//        buf[14] = mEco
        buf[buf.count - 2] = -1
        let checkSum = buf.reduce(0) { $0 + $1 }
        buf[buf.count - 1] = checkSum
        buf[buf.count - 2] = 0xff
        return buf
    }
    
    func getStudyData(data: [UInt8], len: Int) -> [UInt8]? {
        return ETIR.studyKeyCode(data: data, len: len)
    }
    
    func getBrandArray(brandIndex: Int) -> [Int] {
        return ETIR.getBrandArray(type: IRDeviceType.DEVICE_REMOTE_AIR, brandIndex: brandIndex)
    }
    
    func getTypeArray(typeIndex: Int) -> [Int] {
        return ETIR.getTypeArray(type: IRDeviceType.DEVICE_REMOTE_AIR, typeIndex: typeIndex)
    }
    
    func getTypeCount(typeIndex: Int) -> Int {
        //30 01 03 3E 1F 01 03 00 00 01 02 01 01 00 01 03 00 00 FF 9D
        
        return ETIR.getTypeCount(type: IRDeviceType.DEVICE_REMOTE_AIR, typeIndex: typeIndex)
    }
    
    func getBrandCount(brandIndex: Int) -> Int {
        return ETIR.getBrandCount(type: IRDeviceType.DEVICE_REMOTE_AIR, brandIndex: brandIndex)
    }
    
    func getTableCount() -> Int {
        return ETIR.getTableCount(type: IRDeviceType.DEVICE_REMOTE_AIR)
    }
}
