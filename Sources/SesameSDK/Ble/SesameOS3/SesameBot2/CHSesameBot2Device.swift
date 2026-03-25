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
        CHSesamebot2Status(curIdx: 0, eventLength: 0, events: [])
    }()
    
    var isConnectedByWM2 = false
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
            if (self.deviceStatus.loginStatus == .logined ) {
                isHistory = advertisement.adv_tag_b1
            }
        }
    }
    
    public var isHistory: Bool = false {
        didSet {
            if isHistory {
                self.readHistoryCommand(){_ in}
            }
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
            postBatteryData(data[0..<2].toHexString()) { res in
                if case .success(let resp) = res {
                    self.notifyBatteryPercentageChanged(percentage: resp.data)
                }
            }

        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(data.toHexString()) { _ in }
        case .SSM3_ITEM_CODE_BLE_TX_POWER_SETTING:
            guard let value = data.first else { return }
            bleTxPower = value
        default:
            L.d("[bot2][publish]!![\(data.bytes)]")
        }
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
    
    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        URLSession.isInternetReachable { isInternetReachable in
            self.sendCommand(.init( .history, "01".hexStringtoData())) { (result) in // 01: 从设备读取最旧的历史记录
                if result.cmdResultCode == .success {
                    let histItem = result.data.copyData
                    (self.delegate as? CHSesameBot2Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: histItem)))
                    guard isInternetReachable && !self.isConnectedByWM2 else { return }
                    self.postProcessHistory(result.data.copyData) { res in
                        if case .success(_) = res  {
                            let recordId = result.data.copyData[0...3].copyData
                            self.sendCommand(.init(SesameItemCode.historyDelete, recordId)) { response in
                                if response.cmdResultCode == .success  { L.d("[bike2][history]歷史删除成功") }
                            }
                        }
                    }
                } else {
                    (self.delegate as? CHSesameBot2Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }
    
    func postProcessHistory(_ historyData: Data, _ callback: @escaping CHResult<CHEmpty>) {
        CHAPIClient.shared.postHistory(deviceId: self.deviceId.uuidString, payload: historyData.toHexString(), t: "5") { result in
            switch result {
            case .success(_):
                callback(.success(CHResultStateNetworks(input:CHEmpty())))
                break
            case .failure(let error):
                callback(.failure(error))
                break
            }
        }
    }
    
    func setBleTxPower(txPower: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if !isBleAvailable(result) { return }

        sendCommand(.init(.SSM3_ITEM_CODE_BLE_TX_POWER_SETTING, Data([txPower]))) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
}
