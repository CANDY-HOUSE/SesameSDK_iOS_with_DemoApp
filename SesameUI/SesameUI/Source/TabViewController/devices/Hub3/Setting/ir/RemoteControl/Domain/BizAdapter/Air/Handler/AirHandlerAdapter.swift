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

class AirHandlerAdapter: RemoteHandlerAdapter {
    
    private let tag = String(describing: AirHandlerAdapter.self)

    private let uiAdapter: RemoteUIAdapter
    private var uiType: RemoteUIType
    
    // 错误和成功列表
    private var errorList: [String] = []
    private var successList: [String] = []
    
    init(_ uiAdapter: RemoteUIAdapter) {
        self.uiAdapter = uiAdapter
        self.uiType = (uiAdapter as? AirUIAdapter)!.uiType
    }
    
    func handleItemClick(item: IrControlItem, hub3DeviceId: String, remoteDevice: IRRemote) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let command = self.buildCommand(item: item, remoteDevice: remoteDevice)
            
            if command.isEmpty {
                L.d(self.tag, "handleItemClick buildCommand is empty!")
                return
            }
            
            executeOnMainThread {
                self.uiAdapter.setCurrentState(command)
            }
            
            self.postCommand(hub3DeviceId: hub3DeviceId,command: command)
            
            if !remoteDevice.uuid.isEmpty && remoteDevice.haveSave {
                CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remoteDevice.uuid,"state": command]) { [weak self] result in
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
    
    func modifyIRDeviceInfo(hub3DeviceId: String, remoteDevice: IRRemote, onResponse: @escaping CHResult<CHEmpty>) {
        CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remoteDevice.uuid, "alias": remoteDevice.alias]) { [weak self] result in
            onResponse(result)
        }
    }
    
    private func postCommand(hub3DeviceId: String, command: String) {
        CHIRManager.shared.irCodeEmit(hub3DeviceId: hub3DeviceId, code: command, irDeviceUUID:"", irType: getCurrentIRDeviceType() ) { result in
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
            guard let configAdapter = uiAdapter as? AirUIAdapter else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid adapter type"])
            }
            let key = configAdapter.paramsSwapper.getAirKey(item.type)
            let command = configAdapter.commandProcessor.setKey(key).setCode(remoteDevice.code).buildAirCommand()
            return command.map { String(format: "%02X", $0) }.joined()
        } catch {
            print("Build command error: \(error)")
            return ""
        }
    }
    
    func clearHandlerCache() {
        // Implementation
    }
    
    func getCurrentState(remoteDevice: IRRemote) -> String {
        return (uiAdapter as? AirUIAdapter)?.getCurrentState() ?? ""
    }
    
    func getCurrentIRDeviceType() -> Int {
        return uiType.irType
    }
}
