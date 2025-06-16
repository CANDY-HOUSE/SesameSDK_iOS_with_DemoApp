//
//  BleHelper.swift
//  SesameUI
//
//  Created by 姜宗暐 on 2022/1/11.
//  Copyright © 2022 CandyHouse. All rights reserved.
//
// 現在需求：
// 在沒有開啟藍芽僅使用wifi的情況下：
// 1. 打開app時，要跳出"Saseme想要使用藍牙進行連線"的提示訊息
// 2. siri shortcut開關鎖，不跳出"Saseme想要使用藍牙進行連線"的提示訊息
//
// 目前解決方式：
// CBCentralManager分開為UI層和SDK層
// UI層：開啟提示
// SDK層：關閉提示

import Foundation
import CoreBluetooth

class BleHelper: NSObject {
    public static let shared = BleHelper()
    
    var centralManager: CBCentralManager!
    
    @discardableResult
    override init() {
        super.init()
        
        // 初始化藍芽中心設備
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
//        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))

    }
}

// MARK: - CBCentralManagerDelegate
extension BleHelper: CBCentralManagerDelegate {
    // MARK: - centralManagerDidUpdateState
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
}
