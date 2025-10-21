//
//  CHSesameBot2Device.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/13.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBot2Device: CHSesameOS3, CHSesameBot2, CHDeviceUtil {
    
    var scripts: CHSesamebot2Status = {
        var events = [CHSesamebot2Event]()
        for i in 0...9 {
            events.append(CHSesamebot2Event(nameLength: 1, name: [UInt8(48 + i)]))
        }
        let status = CHSesamebot2Status(curIdx: 0, eventLength: 10, events: events)
        return status
    }()
    
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }
    
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {
        case .mechStatus:
            if data.count == 7 {
                mechStatus = Sesame5MechStatus.fromData(data)!
            } else {
                mechStatus = CHSesameBike2MechStatus.fromData(data)!
            }
            self.deviceStatus = mechStatus!.isInLockRange  ? .locked() :.unlocked()
            postBatteryData(data[0..<2].toHexString())

        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(data.toHexString())
        default:
            L.d("[bot2][publish]!![\(data.bytes)]")
        }
    }
    
}

extension CHSesameBot2Device {
    
    func click(index: UInt8? = nil, result: @escaping (CHResult<CHEmpty>)) {
        var itemCode = SesameItemCode.click
        if let idx = index {
            itemCode = SesameItemCode(rawValue: UInt8(SesameItemCode.BOT2_ITEM_CODE_RUN_SCRIPT_0.rawValue) + idx) ?? .click
        }
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(itemCode, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(itemCode, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(itemCode)) { responsePayload in
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
        result(.success(CHResultStateBLE(input:CHEmpty())))
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
        result(.success(CHResultStateBLE(input: self.scripts)))
    }
}
