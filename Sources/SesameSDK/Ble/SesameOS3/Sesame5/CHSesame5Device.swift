//
//  CHSesame5Device.swift
//  SesameSDK
//  [joi fix history]
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import Foundation
import CoreBluetooth

class CHSesame5Device: CHSesameOS3LockBase, CHSesame5 {
    
    var mechSetting: CHSesame5MechSettings?
    var opsSetting: CHSesame5OpsSettings?
    
    override func handleLockDevicePublish(_ payload: SesameOS3PublishPayload) {
        let itemCode = payload.itemCode
        let data = payload.payload
        
        switch itemCode {
        case .mechStatus:
            mechStatus = Sesame5MechStatus.fromData(data)!
            self.readHistoryCommand { _ in }
            self.deviceStatus = mechStatus!.isInLockRange ? .locked() : .unlocked()
            postBatteryData(data[0..<2].toHexString()) { res in
                if case .success(let resp) = res {
                    self.notifyBatteryPercentageChanged(percentage: resp.data)
                }
            }
            
        case .mechSetting:
            mechSetting = CHSesame5MechSettings.fromData(data)!
            
        case .OPS_CONTROL:
            opsSetting = CHSesame5OpsSettings.fromData(data)!
            
        default:
            L.d("!![ss5][pub][\(itemCode.rawValue)]")
        }
    }
    
    override func notifyHistoryReceived(_ result: Result<CHResultState<Data>, Error>) {
        (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: result)
    }
}

extension CHSesame5Device {
    
    // MARK: toggle 开切换
    /// - Parameters:
    ///   - historytag: 历史标签
    ///   - result: 完成回調
    ///   - 1. 设备有影子、未登录，IoT开关锁toggle  2. 如果是在上锁的范围，则开锁   否则，关锁
    ///
    public func toggle(historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(.toggle, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        (mechStatus?.isInLockRange == true) ? unlock(historytag:historytag,result: result) : lock(historytag:historytag,result: result)
    }
    
    // MARK: unlock 开锁
    /// - Parameters:
    ///   - historytag: 历史标签
    ///   - result: 完成回調
    ///   - 1. 设备有影子、未登录，IoT开锁  2. 蓝牙未启用，未登录，IoT开锁  3.  蓝牙启用，直接开关锁
    ///
    public func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        if ((deviceShadowStatus != nil && deviceStatus.loginStatus == .unlogined) || !self.isBleAvailable()) {
            CHIoTManager.shared.sendCommandToWM2(.unlock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(.unlock,historytag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    // MARK: lock 关锁
    /// - Parameters:
    ///   - historytag: 历史标签
    ///   - result: 完成回調
    ///   - 逻辑同上 unlock
    ///
    public func lock(historytag: Data? = Data(), result: @escaping (CHResult<CHEmpty>)) {
        if ((deviceShadowStatus != nil && deviceStatus.loginStatus == .unlogined) || !self.isBleAvailable()) {
            CHIoTManager.shared.sendCommandToWM2(.lock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(.lock,historytag ?? Data())) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    public func autolock(historytag: Data?, delay: Int, result: @escaping (CHResult<Int>)) {
        if(!isBleAvailable(result)){return}
        
        var autolockSet = Sesame2Autolock(Int16(delay))
        let payload = autolockSet.toData()
        
        return sendCommand(.init( .autolock, payload)) { (payload) in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: delay)))
            }
        }
    }
    
    public func opSensorControl(delay: Int, result: @escaping (CHResult<Int>)) {
        if(!isBleAvailable(result)){ return }
        
        let payload = Data(withUnsafeBytes(of: UInt16(delay)) { Data($0) })// 限制內容不超過兩個byte
        sendCommand(.init(.OPS_CONTROL, payload)) { (payload) in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: delay)))
            }
        }
    }
    
    public func configureLockPosition(lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>)) {
        if(!isBleAvailable(result)){return}
        
        var configure = CHSesame5LockPositionConfiguration(lockTarget: lockTarget, unlockTarget: unlockTarget)
        let payload = configure.toData()
        
        sendCommand(.init(.mechSetting, payload)) { (responsePayload) in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
            
        }
    }
    
    public func sendAdvProductTypeCommand(data: Data, result: @escaping (CHResult<CHEmpty>)) {
        if (!isBleAvailable(result)) { return }
        
        sendCommand(.init(.SS3_ITEM_CODE_SET_ADV_PRODUCT_TYPE, data)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func magnet(result: @escaping (CHResult<CHEmpty>)) {
        if(!isBleAvailable(result)){return}
        
        sendCommand(.init(.magnet)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
}

struct Sesame5MechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let target: Int16
    let position: Int16
    let flags: UInt8
    var data: Data {battery.data + target.data + position.data  + flags.data}
    var isClutchFailed: Bool { return flags & 1 > 0 }
    var isInLockRange: Bool { return flags & 2 > 0 }
    var isInUnlockRange: Bool { return flags & 4 > 0 }
    var isStop: Bool? { return flags & 16 > 0 }
    var isBatteryCritical: Bool { return flags & 32 > 0 }
    var isCritical: Bool? { return flags & 8 > 0 }
    
    static func fromData(_ buf: Data) -> Sesame5MechStatus? {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
