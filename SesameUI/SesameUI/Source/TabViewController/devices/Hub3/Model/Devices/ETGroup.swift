//
//  ETGroup.swift
//  SesameUI
//
//  Created by eddy on 2024/6/14.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

class ETGroup: NSObject {
    var mID: String
    var mName: String
    var mType: Int
    var mResId: Int
    var mDeviceList: [ETDevice]
    
    override init() {
        mID = ""
        mName = ""
        mType = 0
        mResId = 0
        mDeviceList = [ETDevice]()
        super.init()
    }
}

extension ETGroup: IOp {
    func load(db: ETDB, completion: @escaping() -> Void) {
        mDeviceList.removeAll()
        db.fetchDevicesByGroupId(mID) { [self] irDevices in
            guard let irDs = irDevices else { return }
            for irD in irDs {
                let device = ETDevice.Builder(type: Int(irD.device_type))
                device?.mID = Int(irD.id)
                device?.mGID = irD.gid
                device?.mName = irD.device_name
                device?.mType = Int(irD.device_type)
                device?.mResId = Int(irD.device_res)
                device?.load(db: db){}
                self.mDeviceList.append(device!)
            }
            completion()
//            添加设备入口，暂时屏蔽
//            let addDevice = ETDevice()
//            addDevice.mID = 0
//            addDevice.mName = ""
//            addDevice.mType = IRDeviceType.DEVICE_ADD
//            addDevice.mResId = ETGlobal.mDeviceImages.length - 1
        }
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
