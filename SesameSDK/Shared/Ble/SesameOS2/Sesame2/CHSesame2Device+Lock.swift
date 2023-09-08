//
//  CHSesame2Device+Lock.swift
//  Sesame2SDK
//
//  Created by tse on 2019/12/10.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

extension CHSesame2Device {
    
    public func toggle(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
//            CHIoTManager.shared.sendCommandToWM2(.toggle, self) { _ in
//                result(.success(CHResultStateNetworks(input: CHEmpty())))
//            }
            return
        }
        
        guard let isLocked = mechStatus?.isInLockRange  else {
            result(.failure(NSError.sesameLockNotInLockRangeError))
            return
        }
        isLocked ? unlock(historytag:historytag,result: result) : lock(historytag:historytag,result: result)
    }

    public func lock(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        
        let tagCount_hisTag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            L.d("📡 lock by IoT")
//            L.d("⚠️ \(deviceId.uuidString) lock by IoT")
//            CHIoTManager.shared.sendCommandToWM2(.lock, self) { _ in
//                result(.success(CHResultStateNetworks(input: CHEmpty())))
//            }
            return
        }
        
        if (self.checkBle(result)) { return }
//        L.d("📡 lock by ble")
//        L.d("藍芽", "REQUEST", "下開鎖指令")
        sendCommand(.init(.async, .lock,tagCount_hisTag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
//                L.d("藍芽", "RESPONSE", "下開鎖指令", "成功")
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                L.d("藍芽", "RESPONSE", "下開鎖指令", "失敗")
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

    public func unlock(historytag: Data?,result: @escaping (CHResult<CHEmpty>))  {
        let tagCount_hisTag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            L.d("📡 unlock by IoT")
//            L.d("⚠️ \(deviceId.uuidString) unlock by IoT")
//            CHIoTManager.shared.sendCommandToWM2(.unlock, self) { _ in
//                result(.success(CHResultStateNetworks(input: CHEmpty())))
//            }
            return
        }
        
        if (self.checkBle(result)) { return }
//        L.d("📡 unlock by ble")
//        L.d("藍芽", "REQUEST", "下解鎖指令")
        
        sendCommand(.init(.async, .unlock,tagCount_hisTag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
//                L.d("藍芽", "REQUEST", "下解鎖指令", "成功")
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
//                L.d("藍芽", "REQUEST", "下解鎖指令", "失敗")
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    public func enableAutolock(historytag: Data?,delay: Int, result: @escaping (CHResult<Int>))  {
        if(checkBle(result)){return}
        var autolockSet = Sesame2Autolock(Int16(delay))
        let tagCount_hisTag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        let payload = autolockSet.toData() + tagCount_hisTag
        
        return sendCommand(.init(.update, .autolock, payload)) { (payload) in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: delay)))
            }
        }
    }

    public func getAutolockSetting(result: @escaping (CHResult<Int>))  {
        if(checkBle(result)){return}

        sendCommand(.init(.read, .autolock)) { (payload) in
            if let autolockSetting = Sesame2Autolock.fromData(payload.data) {
//                self.autolockSetting = autolockSetting
                result(.success(CHResultStateBLE(input: Int(autolockSetting.seconds))))
            }
        }
    }

    public func configureLockPosition(historytag: Data?,lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>)) {
        if(checkBle(result)){return}

        var configure = CHSesame2LockPositionConfiguration(lockTarget: lockTarget, unlockTarget: unlockTarget)
        let tmpSetting = configure.toData()
        let tagCount_hisTag = Data.createHistag(historytag ?? sesame2KeyData?.historyTag)
        let payload = configure.toData() + tagCount_hisTag

        sendCommand(.init(.update, .mechSetting, payload)) { (responsePayload) in
            L.d("sdk 設定角度成功",responsePayload.cmdResultCode.plainName)
            if responsePayload.cmdResultCode == .success {
                self.mechSetting = CHSesame2MechSettings.fromData(tmpSetting)
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
            
        }
    }

}
