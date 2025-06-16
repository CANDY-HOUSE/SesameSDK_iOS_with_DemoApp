//
//  ETDevice.swift
//  SesameUI
//
//  Created by eddy on 2024/6/7.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

typealias ETDB = SesameIRStore

protocol IOp {
    func load(db: ETDB, completion: @escaping() -> Void)
    func update(db: ETDB)
    func delete(db: ETDB)
    func insert(db: ETDB)
    func getCount() -> Int
    func getItem(index: Int) -> Any
}

public class ETKeyEx {
  
    var mID: Int = 0
    var mDID: Int = 0
    var mName: String = ""
    var mKeyValue: Data = Data()
    var mKey: Int = 0

    init() {
    }
    // Custom initializer
    public init(mID: Int, mDID: Int, mName: String, mKeyValue: Data, mKey: Int) {
        self.mID = mID
        self.mDID = mDID
        self.mName = mName
        self.mKeyValue = mKeyValue
        self.mKey = mKey
    }
}

extension ETKeyEx: IOp {
    func load(db: ETDB, completion: @escaping() -> Void) {
        
    }
    
    func update(db: ETDB) {
    
    }
    
    func delete(db: ETDB) {
        
    }
    
    func insert(db: ETDB) {
        
    }
    
    func getCount() -> Int {
        return 0
    }
    
    func getItem(index: Int) -> Any {
        return 0
    }
}

class ETKey {
    
    // Ensure the IOp protocol is defined in Swift
    public static let ETKEY_STATE_STUDY = 0x00000001
    public static let ETKEY_STATE_KNOWN = 0x00000002
    public static let ETKEY_STATE_TYPE = 0x00000003
    public static let ETKEY_STATE_DIY = 0x00000004
    public static let ETKEY_STATE_NET = 0x00000005
    public static let ETKEY_STATE_FAST_EX = 0x00000006

    var mID: Int = 0
    var mDID: Int = 0
    var mName: String? = ""
    var mResId: Int = 0
    var mX: Float = 0.0
    var mY: Float = 0.0
    var mKeyValue: [Int] = []
    var mKey: Int = 0
    var mBrandIndex: Int = 0
    var mBrandPos: Int = 0
    var mRow: Int = 0
    var mState: Int = 0
    
    init() {
    }

    init(id: Int, did: Int, name: String, x: Float, y: Float, keyValue: [UInt8], key: Int, brandIndex: Int, brandPos: Int, row: Int, state: Int) {
    }
}

extension ETKey: IOp {
    public func load(db: ETDB, completion: @escaping() -> Void) {
        
    }
    
    public func update(db: ETDB) {
        
    }
    
    public func delete(db: ETDB) {
        
    }
    
    public func insert(db: ETDB) {
        db.insertDeviceKey(self) { yesOrNo in
            if yesOrNo {
                L.d("Device Key 入库成功")
            }
        }
    }
    
    public func getCount() -> Int {
        return 0
    }
    
    public func getItem(index: Int) -> Any {
        return 0
    }
}

public class ETDevice: IOp {
    
    func getCount() -> Int {
        return 0
    }
    
    func getItem(index: Int) -> Any {
        return 0
    }
    
    var m20: Int = 0xff
    var m08: Int = 0xff
    var m10: Int = 0xff
    var mID: Int?
    var mGID: String?
    var mName: String?
    var mType: Int?
    var mResId: Int?
    var mKeyList: [ETKey] // 确保定义了 ETKey 类
    var mKeyExList: [ETKeyEx] // 确保定义了 ETKeyEx 类

    public init() {
        mKeyList = [ETKey]()
        mKeyExList = [ETKeyEx]()
    }

    public static func Builder(type: Int) -> ETDevice? {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_AIR:    return ETDeviceAir()
        case IRDeviceType.DEVICE_REMOTE_CUSTOM: return ETDeviceCustom()
        default:
            return nil
        }
    }
 
    private func Set20(value: Int) {
        m20 = value
    }

    private func Get20() -> Int {
        return m20
    }

    private func Set08(value: Int) {
        m08 = value
    }

    private func Get08() -> Int {
        return m08
    }

    private func Set10(value: Int) {
        m10 = value
    }

    private func Get10() -> Int {
        return m10
    }

    public func Study(key: [UInt8]) -> [UInt8] {
        return ETIR.studyKeyCode(data: key, len: key.count)!
    }

    public func Work(key: inout [UInt8]) -> [UInt8] {
        if key[2] == 0x04 {
            if Get20() == 0xFF {
                Set20(value: Int(key[5]))
            } else {
                var value = Get20()
                value ^= 0x20
                Set20(value: value)
                key[5] = UInt8(Get20())
            }
        } else if key[2] == 0x0A {
            if Get08() == 0xFF {
                Set08(value: Int(key[5]))
            } else {
                var value = Get08()
                value ^= 0x08
                Set08(value: value)
                key[5] = UInt8(Get08())
            }
        } else if key[2] == 0x21 {
            if Get10() == 0xFF {
                Set10(value: Int(key[5]))
            } else {
                var value = Get10()
                value ^= 0x10
                Set10(value: value)
                key[5] = UInt8(Get10())
            }
        }
        key[9] = UInt8(key[0...8].reduce(0, {$0 + $1}))
        Set20(value: 0xFF)
        Set08(value: 0xFF)
        Set10(value: 0xFF)
        return key
    }
    
    // MARK: IOP impl
    func load(db: ETDB, completion: @escaping() -> Void) {
        mKeyList.removeAll()
        db.fetchETKeysByDeviceId(mID!) { [self] keys in
            guard let getKeys = keys else { return }
            for item in getKeys {
                let etKey = ETKey()
                etKey.mID = Int(item.id)
                etKey.mDID = Int(item.did)
                etKey.mName = item.key_name ?? ""
                etKey.mState = Int(item.key_state)
                etKey.mResId = Int(item.key_res)
                etKey.mRow = Int(item.key_row)
                etKey.mBrandIndex = Int(item.key_brandindex)
                etKey.mBrandPos = Int(item.key_brandpos)
                etKey.mKey = Int(item.key_key)
                etKey.mKeyValue = item.key_value!.hexStringToBytes()?.compactMap{ Int($0) } ?? []
                etKey.mX = item.key_x
                etKey.mY = item.key_y
                self.mKeyList.append(etKey)
            }
        }
        // keyEx 暂时忽略
    }
    
    func update(db: ETDB) {
        
    }
    
    func delete(db: ETDB) {
        db.deleteDevicesById(Int(mID!)) { yesOrNo in
            L.d("Device & Keys 删库成功")
        }
    }
    
    func insert(db: ETDB) {
        // 设备入库
        db.fetchLatestDeviceId { [self] deviceId in
            if let did = deviceId {
                mID = Int(did + 1)
            } else {
                mID = 0
            }
        }
//        // 按键 keyEx 入库
//        for keyEx in self.mKeyExList {
//            keyEx.mDID = mID
//            keyEx.insert(db: SesameIRStore.instance)
//        }
//    }
    }
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
