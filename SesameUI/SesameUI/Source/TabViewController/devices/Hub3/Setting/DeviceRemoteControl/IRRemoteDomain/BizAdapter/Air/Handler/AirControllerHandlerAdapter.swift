//
//  AirControllerHandlerAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

class AirControllerHandlerAdapter: HandlerConfigAdapter {
    private let tag = String(describing: AirControllerHandlerAdapter.self)
    private let air = AirProcessor()
    private let uiConfigAdapter: UIConfigAdapter
    
    // 错误和成功列表
    private var errorList: [String] = []
    private var successList: [String] = []
    
    init(uiConfigAdapter: UIConfigAdapter) {
        self.uiConfigAdapter = uiConfigAdapter
        air.setupTable()
    }
    
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            let key = self.getCurrentKey(item: item)
            let command = self.buildCommand(operationKey: key, remoteDevice: remoteDevice)
            
            if command.isEmpty {
                L.d(self.tag, "handleItemClick buildCommand is empty!")
                return
            }
            
            L.d(
                self.tag,
                "handleItemClick buildCommand is:command=\(command), device:\(device.deviceId.uuidString.uppercased())"
            )
            
            executeOnMainThread {
                self.uiConfigAdapter.setCurrentState(command)
            }
            
            self.postCommand(
                device: device,
                deviceId: device.deviceId.uuidString.uppercased(),
                command: command
            )
            
            if !remoteDevice.uuid.isEmpty && remoteDevice.haveSave {
                device.updateIRDevice([
                    "uuid": remoteDevice.uuid,
                    "state": command
                ]) { [weak self] result in
                    switch result {
                    case .success:
                        L.d(self?.tag, "update state success{\(remoteDevice.uuid):\(command)}")
                    case .failure(let error):
                        L.d(self?.tag, "update state failed: \(error)")
                    }
                }
            }
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    func modifyIRDeviceInfo(device: CHHub3, remoteDevice: IRRemote, onResponse: @escaping SesameSDK.CHResult<CHEmpty>) {
        device.updateIRDevice([
            "uuid": remoteDevice.uuid,
            "alias": remoteDevice.alias
        ]) { [weak self] result in
            onResponse(result)
        }
    }
    
    private func postCommand(device: CHHub3, deviceId: String, command: String) {
        device.irCodeEmit(id: command, irDeviceUUID:"" ) { result in
            switch result {
            case .success(let data):
                L.d(self.tag, "emitIRRemoteDeviceKey success \(data)")
            case .failure(let error):
                L.d(self.tag, "emitIRRemoteDeviceKey error :\(error.localizedDescription)")
            }
        }
    }
    
    private func buildCommand(operationKey: Int, remoteDevice: IRRemote) -> String {
        do {
            guard let configAdapter = uiConfigAdapter as? AirControllerConfigAdapter else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid adapter type"])
            }
            
            air.buildParamsWithPower(getPower(configAdapter.getPower()))
                .buildParamsWithModel(getMode(configAdapter.getModeIndex()))
                .buildParamsWithTemperature(getTemperature(configAdapter.getTemperature()))
                .buildParamsWithFanSpeed(getFanSpeed(configAdapter.getFanSpeedIndex()))
                .buildParamsWithWindDirection(getVerticalSwingIndex(configAdapter.getVerticalSwingIndex()))
                .buildParamsWithAutomaticWindDirection(getHorizontalSwingIndex(configAdapter.getHorizontalSwingIndex()))
            
            air.mKey = operationKey
            let data = try air.search(arrayIndex:remoteDevice.code)
            return data.map { String(format: "%02X", $0) }.joined()
        } catch {
            print("Build command error: \(error)")
            return ""
        }
    }
    
    func clearHandlerCache() {
        // Implementation
    }
    
    func getCurrentState(device: CHHub3, remoteDevice: IRRemote) -> String {
        return (uiConfigAdapter as? AirControllerConfigAdapter)?.getCurrentState() ?? ""
    }
    
    func getCurrentIRDeviceType() -> Int {
        return IRType.DEVICE_REMOTE_AIR
    }
    
    // MARK: - Helper Methods
    
    func getPower(_ isPowerOn: Bool) -> Int {
        return isPowerOn ? 0x01 : 0x00
    }
    
    func getMode(_ mode: Int) -> Int {
        switch mode {
        case 0: return 0x01
        case 1: return 0x02
        case 2: return 0x03
        case 3: return 0x04
        case 4: return 0x05
        default: return 0x01
        }
    }
    
    func getFanSpeed(_ index: Int) -> Int {
        switch index {
        case 0: return 0x01
        case 1: return 0x02
        case 2: return 0x03
        case 3: return 0x04
        default: return 0x01
        }
    }
    
    func getVerticalSwingIndex(_ index: Int) -> Int {
        switch index {
        case 0: return 0x01
        case 1: return 0x02
        case 2: return 0x03
        default: return 0x02
        }
    }
    
    func getHorizontalSwingIndex(_ index: Int) -> Int {
        switch index {
        case 0: return 0x01
        case 1: return 0x00
        default: return 0x01
        }
    }
    
    func getTemperature(_ temperature: Int) -> Int {
        return temperature
    }
    
    func getCurrentKey(item: IrControlItem) -> Int {
        switch item.type {
        case .powerStatusOn, .powerStatusOff:
            return 0x01
        case .tempControlAdd:
            return 0x06
        case .tempControlReduce:
            return 0x07
        case .mode:
            return 0x02
        case .fanSpeed:
            return 0x03
        case .swingVertical:
            return 0x04
        case .swingHorizontal:
            return 0x05
        default:
            L.d(tag, "Unknown item type")
            return 0x01
        }
    }
    
}
