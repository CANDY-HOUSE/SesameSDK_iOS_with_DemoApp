//
//  CHSesame5Device+Command.swift
//  SesameSDK
//
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import CoreBluetooth

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
    
    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }
    
    public func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                //                L.d("[ss5]",versionTag)
                result(.success(CHResultStateNetworks(input: versionTag)))
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
    }
    
    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.reset)) { (responsePayload) in
            self.dropKey { dropResult in
                switch dropResult {
                case .success(_):
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
    }
    
    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else {
            return
        }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { res in
            //            L.d("[ss5][login]",res.data.toHexString())
            let  time = Sesame5Time.fromData(res.data).time
            let sesameTime = Date(timeIntervalSince1970: TimeInterval(time))
            //            L.d("[ss5][time]", sesameTime.description(with: .current))
            //            L.d("[ss5][phonetime]", Date().description(with: .current))
            
            let timeErrorInterval = sesameTime.timeIntervalSince1970 - Date().timeIntervalSince1970
            //            L.d("[ss5][timeErrorInterval]", timeErrorInterval)
            if abs(timeErrorInterval) > 3 {
                L.d("[ss5][timeErrorInterval>3]", timeErrorInterval)
                var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
                let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
                self.sendCommand(.init(.time,timestampData)) { res in
                    L.d("[ss5][cmd]", timeErrorInterval,res.cmdResultCode.plainName)
                }
            }
        }
    }
}
