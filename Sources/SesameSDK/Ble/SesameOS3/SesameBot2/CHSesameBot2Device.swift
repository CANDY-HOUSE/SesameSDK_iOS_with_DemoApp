//
//  CHSesameBot2Device.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/13.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBot2Device: CHSesameOS3LockBase, CHSesameBot2 {
    
    var scripts: CHSesamebot2Status = {
        CHSesamebot2Status(curIdx: 0, eventLength: 0, events: [])
    }()
    
    override func handleLockDevicePublish(_ payload: SesameOS3PublishPayload) {
        let itemCode = payload.itemCode
        let data = payload.payload
        
        switch itemCode {
        case .mechStatus:
            if data.count == 7 {
                mechStatus = Sesame5MechStatus.fromData(data)!
            } else {
                mechStatus = CHSesameBike2MechStatus.fromData(data)!
            }
            self.deviceStatus = mechStatus!.isInLockRange ? .locked() : .unlocked()
            postBatteryData(data[0..<2].toHexString()) { res in
                if case .success(let resp) = res {
                    self.notifyBatteryPercentageChanged(percentage: resp.data)
                }
            }
            
        default:
            L.d("[bot2][publish]!![\(data.bytes)]")
        }
    }
    
    override func notifyHistoryReceived(_ result: Result<CHResultState<Data>, Error>) {
        (self.delegate as? CHSesameBot2Delegate)?.onHistoryReceived(device: self, result: result)
    }
}

extension CHSesameBot2Device {
    
    func click(index: UInt8? = nil, historytag: Data?, result: @escaping (CHResult<CHEmpty>)) {
        var itemCode = SesameItemCode.click
        if let idx = index {
            itemCode = SesameItemCode(rawValue: UInt8(SesameItemCode.BOT2_ITEM_CODE_RUN_SCRIPT_0.rawValue) + idx) ?? .click
        }
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(itemCode, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(itemCode, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(itemCode,historytag)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func sendClickScript(index: UInt8, script: Data, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.BOT2_ITEM_CODE_EDIT_SCRIPT, Data([index]) + script)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func selectScript(index: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.scriptSelect, index != nil ? Data([index]) : nil)) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func getCurrentScript(index: UInt8?, result: @escaping (CHResult<CHSesamebot2Event>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.scriptCurrent, index != nil ? Data([index!]) : nil)) { payload in
            L.d("[getCurrentScript] all: ", payload.data.bytes)
            if payload.cmdResultCode == .success {
                if let resp = CHSesamebot2Event.fromData(payload.data) {
                    result(.success(CHResultStateBLE(input: resp)))
                } else {
                    result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
                }
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func getScriptNameList(result: @escaping (CHResult<CHSesamebot2Status>)) {
        if !self.isBleAvailable(result) { return }
        sendCommand(.init(.scriptNameList, nil)) { payload in
            if payload.cmdResultCode == .success {
                if let status = CHSesamebot2Status.fromData(payload.data) {
                    self.scripts = status
                    result(.success(CHResultStateBLE(input: status)))
                } else {
                    result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
                }
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
}
