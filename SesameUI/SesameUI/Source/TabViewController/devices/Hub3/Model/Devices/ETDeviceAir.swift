//
//  ETDeviceAir.swift
//  SesameUI
//
//  Created by eddy on 2024/6/7.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

class ETDeviceAir: ETDevice {
    
    let air: Air
    var keys = [ETKey]()
    
    override init() {
        air = ETIR.builder(type: IRDeviceType.DEVICE_REMOTE_AIR) as! Air
    }
    
    func setKey(_ key: ETKey) {
        mKeyList.append(key)
    }
    
    init(row: Int, isFast: Bool) {
        air = ETIR.builder(type: IRDeviceType.DEVICE_REMOTE_AIR) as! Air
        super.init()
        for i in 0 ..< IRDeviceType.REMOTE_KEY_AIR.KEY_COUNT {
            let key = ETKey()
            key.mKey = IRDeviceType.DEVICE_REMOTE_AIR | (i * 2 + 1)
            key.mRow = row
            if isFast {
                key.mState = ETKey.ETKEY_STATE_FAST_EX
                key.mKeyValue = air.search(arrayIndex: row, key: key.mKey)
            } else {
                key.mState = ETKey.ETKEY_STATE_TYPE
                let typeArr = air.getTypeArray(typeIndex: row)
                let keyValues = air.search(arrayIndex: typeArr.first!, key: key.mKey)
                key.mKeyValue = keyValues
            }
            setKey(key)
        }
    }
    
    func getKeyValue(_ value: Int) -> [Int] {
        let key = mKeyList.first(where: { $0.mKey == value })!
        let typeArr = air.getTypeArray(typeIndex: key.mRow)
        return air.search(arrayIndex: typeArr.first!, key: key.mKey)
    }
    
    override func load(db: ETDB, completion: @escaping () -> Void) {
        super.load(db: db, completion: completion)
        db.fetchAirByDeviceId(mID!) { [self] device in
            guard let irD = device else { return }
            air.mTemperature = Int(irD.air_temp)
            air.mWindRate = Int(irD.air_rate)
            air.mWindDirection = Int(irD.air_dir)
            air.mAutomaticWindDirection = Int(irD.air_auto_dir)
            air.mMode = Int(irD.air_mode)
            air.mPower = Int(irD.air_power)
            air.mSleep = Int(irD.air_sleep)
            air.mHeat = Int(irD.air_heat)
            air.mLight = Int(irD.air_light)
            air.mEco = Int(irD.air_eco)
        }
    }
    
    override func insert(db: ETDB) {
        super.insert(db: db)
        db.insertDevice(self, keys: self.mKeyList) { yesOrNo in
            if yesOrNo {
                L.d("Device 入库成功")
            }
        }
    }
    
    override func update(db: ETDB) {
        super.update(db: db)
        db.fetchAirByDeviceId(mID!) { [self] airInfo in
            guard let irD = airInfo else { return }
            irD.air_temp = Int16(air.mTemperature)
            irD.air_rate = Int16(air.mWindRate)
            irD.air_dir = Int16(air.mWindDirection)
            irD.air_auto_dir = Int16(air.mAutomaticWindDirection)
            irD.air_mode = Int16(air.mMode)
            irD.air_power = Int16(air.mPower)
            irD.air_sleep = Int16(air.mSleep)
            irD.air_heat = Int16(air.mHeat)
            irD.air_light = Int16(air.mLight)
            irD.air_eco = Int16(air.mEco)
            db.saveChanges { yesOrNo, err in }
        }
    }
    
    override func delete(db: ETDB) {
        super.delete(db: db)
    }
}
