//
//  BleHelper.swift
//  SesameUI
//
//  Created by 姜宗暐 on 2022/1/11.
//  Copyright © 2022 CandyHouse. All rights reserved.

import Foundation
import CoreBluetooth

class BleHelper: NSObject {
    public static let shared = BleHelper()
    
    var centralManager: CBCentralManager!
    
    @discardableResult
    override init() {
        super.init()
        
        // 初始化藍芽中心設備
        centralManager = CBCentralManager(delegate: self, queue:DispatchQueue.global())
    }
}

// MARK: - CBCentralManagerDelegate
extension BleHelper: CBCentralManagerDelegate {
    // MARK: - centralManagerDidUpdateState
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}
