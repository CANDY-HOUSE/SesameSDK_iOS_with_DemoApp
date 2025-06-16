//
//  LightControllerHandlerAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

class LightControllerHandlerAdapter: HandlerConfigAdapter {
    private let tag = "LightControllerHandlerAdapter"
    private let uiConfigAdapter: UIConfigAdapter
    private let air = AirProcessor()
    
    init(uiConfigAdapter: UIConfigAdapter) {
        self.uiConfigAdapter = uiConfigAdapter
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
            // 发送命令
            self.postCommand(device: device, deviceId: device.deviceId.uuidString.uppercased(), command: command)
            // 更新设备状态
            if !remoteDevice.uuid.isEmpty && remoteDevice.haveSave {
                self.updateDeviceState(device: device, remoteDevice: remoteDevice, command: command)
            }
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    private func updateDeviceState(device: CHHub3, remoteDevice: IRRemote, command: String) {
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
    
    
    func modifyIRDeviceInfo(device: CHHub3, remoteDevice: IRRemote, onResponse: @escaping SesameSDK.CHResult<CHEmpty>) {
        device.updateIRDevice([
            "uuid": remoteDevice.uuid,
            "alias": remoteDevice.alias
        ]) { result in
            onResponse(result)
        }
    }
    
    private func postCommand(device: CHHub3, deviceId: String, command: String) {
        device.irCodeEmit(id: command, irDeviceUUID:"") { result in
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
            guard let configAdapter = uiConfigAdapter as? LightControllerConfigAdapter else { return "" }
            let row = configAdapter.getTableRow(remoteDevice.code)
            var buf: [UInt8] = []
            
            buf.append(0x30)
            buf.append(0x00)
            buf.append(UInt8(row[0]))
            buf.append(UInt8(row[(operationKey - 1) * 2 + 1]))
            buf.append(UInt8(row[(operationKey - 1) * 2 + 2]))
            buf.append(UInt8(row[row.count - 4]))
            buf.append(UInt8(row[row.count - 3]))
            buf.append(UInt8(row[row.count - 2]))
            buf.append(UInt8(row[row.count - 1]))
            
            // 计算校验和
            let checksum = UInt8(buf.reduce(0) { $0 + Int($1) } & 0xFF)
            buf.append(checksum)
            
            return buf.map { String(format: "%02X", $0) }.joined()
        } catch {
            print(error)
            return ""
        }
    }
    
    func clearHandlerCache() {
        // Implementation needed
    }
    
    func setHandlerCallback(handlerCallback: HandlerCallback) {
        // Implementation needed
    }
    
    func getCurrentState(device: CHHub3, remoteDevice: IRRemote) -> String {
        return (uiConfigAdapter as! LightControllerConfigAdapter).getCurrentState()
    }
    
    func getCurrentIRDeviceType() -> Int {
        return IRType.DEVICE_REMOTE_LIGHT
    }
    
    func getCurrentKey(item: IrControlItem) -> Int {
        switch item.type {
        case .powerStatusOn:
            return 0x01
        case .powerStatusOff:
            return 0x02
        case .mode:
            return 0x05
        case .brightnessUp:
            return 0x03
        case .brightnessDown:
            return 0x04
        case .colorTempUp:
            return 0x09
        case .colorTempDown:
            return 0x0A
        default:
            L.d(tag, "Unknown item type")
            return 0x01
        }
    }
}
