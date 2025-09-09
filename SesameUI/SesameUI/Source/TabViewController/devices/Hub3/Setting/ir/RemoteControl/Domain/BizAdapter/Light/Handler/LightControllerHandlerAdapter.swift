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
    
    init(uiConfigAdapter: UIConfigAdapter) {
        self.uiConfigAdapter = uiConfigAdapter
    }
    
    func handleItemClick(item: IrControlItem, hub3DeviceId: String, remoteDevice: IRRemote) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let command = self.buildCommand(item: item, remoteDevice: remoteDevice)
            
            guard !command.isEmpty else {
                return
            }
            
            executeOnMainThread {
                self.uiConfigAdapter.setCurrentState(command)
            }
            // 发送命令
            self.postCommand(hub3DeviceId: hub3DeviceId, command: command)
            // 更新设备状态
            if !remoteDevice.uuid.isEmpty && remoteDevice.haveSave {
                self.updateDeviceState(hub3DeviceId: hub3DeviceId, remoteDevice: remoteDevice, command: command)
            }
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    private func updateDeviceState(hub3DeviceId: String, remoteDevice: IRRemote, command: String) {
        CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remoteDevice.uuid,"state": command]) { [weak self] result in
            switch result {
            case .success:
                L.d(self?.tag, "update state success{\(remoteDevice.uuid):\(command)}")
            case .failure(let error):
                L.d(self?.tag, "update state failed: \(error)")
            }
        }
    }
    
    
    func modifyIRDeviceInfo(hub3DeviceId: String, remoteDevice: IRRemote, onResponse: @escaping CHResult<CHEmpty>) {
        CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remoteDevice.uuid,"alias": remoteDevice.alias]) { result in
            onResponse(result)
        }
    }
    
    private func postCommand(hub3DeviceId: String, command: String) {
        CHIRManager.shared.irCodeEmit(hub3DeviceId: hub3DeviceId, code: command, irDeviceUUID:"", irType: getCurrentIRDeviceType()) { result in
            switch result {
            case .success(let data):
                L.d(self.tag, "emitIRRemoteDeviceKey success \(data)")
            case .failure(let error):
                L.d(self.tag, "emitIRRemoteDeviceKey error :\(error.localizedDescription)")
            }
        }
    }
    
    private func buildCommand(item: IrControlItem, remoteDevice: IRRemote) -> String {
        do {
            guard let configAdapter = uiConfigAdapter as? LightControllerConfigAdapter else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid adapter type"])
            }
            
            let key = configAdapter.paramsSwapper.getLightKey(item.type)
            let command = configAdapter.commandProcessor.setKey(key).setCode(remoteDevice.code).buildNoneAirCommand()
            guard !command.isEmpty else {
                L.d(tag, "buildCommand buildNoneAirCommand is empty!")
                return ""
            }
            return command.map { String(format: "%02X", $0) }.joined()
        } catch {
            print("Build command error: \(error)")
            return ""
        }
    }
    
    func clearHandlerCache() {
        // Implementation needed
    }
    
    func setHandlerCallback(handlerCallback: HandlerCallback) {
        // Implementation needed
    }
    
    func getCurrentState(remoteDevice: IRRemote) -> String {
        return (uiConfigAdapter as! LightControllerConfigAdapter).getCurrentState()
    }
    
    func getCurrentIRDeviceType() -> Int {
        return IRType.DEVICE_REMOTE_LIGHT
    }
}
