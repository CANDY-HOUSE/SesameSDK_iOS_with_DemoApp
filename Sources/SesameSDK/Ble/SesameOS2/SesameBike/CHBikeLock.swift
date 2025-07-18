//
//  CHSesameBike.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

public protocol CHSesameBikeDelegate: CHDeviceStatusDelegate {}
public protocol CHSesameBike: CHSesameLock {
    func unlock(historytag:Data? ,result: @escaping (CHResult<CHEmpty>))

}
extension CHSesameBike {
    public func unlock(result: @escaping (CHResult<CHEmpty>)) {
        unlock(historytag: nil, result: result)
    }
}
