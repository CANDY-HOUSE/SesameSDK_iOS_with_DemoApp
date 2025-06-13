//
//  ETDeviceCustom.swift
//  SesameUI
//
//  Created by eddy on 2024/7/15.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

class ETDeviceCustom: ETDevice {
    override func insert(db: ETDB) {
        super.insert(db: db)
        db.insertDevice(self, keys: self.mKeyList) { yesOrNo in
            if yesOrNo {
                L.d("Device 入库成功")
            }
        }
    }
}
