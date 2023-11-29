//
//  CHSwitchDevice+Lock.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHSesameBotDevice {
    
    public func lock(historytag: Data? ,result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined { return }
        
        if (self.checkBle(result)) { return }
        let tag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        sendCommand(.init(.async, .lock, tag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    public func unlock(historytag: Data?,result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined { return }
        
        if (self.checkBle(result)) { return }
        let tag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        sendCommand(.init(.async, .unlock, tag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    public func click(historytag: Data?,result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {return}
        
        if (self.checkBle(result)) { return }
        let tag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        sendCommand(.init(.async, .click, tag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    public func toggle(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        let tag = Data.createHistag(historytag ?? self.sesame2KeyData?.historyTag)
        #if os(iOS)
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined { return }
        #endif
        
        if (self.checkBle(result)) { return }
        if mechStatus?.isInLockRange == true {
            unlock(historytag: tag, result: result)
        } else if mechStatus?.isInUnlockRange == true {
            lock(historytag: tag, result: result)
        }
    }
}
