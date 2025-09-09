//
//  TVControllerHandlerAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


/// TV控制器处理适配器
final class TVControllerHandlerAdapter: HandlerConfigAdapter {
    // MARK: - Private Properties
    private let tag = String(describing: TVControllerHandlerAdapter.self)
    private let uiConfigAdapter: UIConfigAdapter
    private var handlerCallback: HandlerCallback?
    
    // MARK: - Initialization
    init(uiConfigAdapter: UIConfigAdapter) {
        self.uiConfigAdapter = uiConfigAdapter
    }
    
    // MARK: - HandlerConfigAdapter Implementation
    func handleItemClick(item: IrControlItem, hub3DeviceId: String, remoteDevice: IRRemote) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let command = self.buildCommand(item: item, remoteDevice: remoteDevice)
            guard !command.isEmpty else {
                L.d(self.tag, "handleItemClick buildCommand is empty!")
                return
            }
            // 更新UI状态
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
    }
    
    func modifyIRDeviceInfo(hub3DeviceId: String, remoteDevice: IRRemote, onResponse: @escaping CHResult<CHEmpty>) {
        CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remoteDevice.uuid, "alias": remoteDevice.alias]) { result in
            onResponse(result)
        }
    }
    
    func clearHandlerCache() {
        // 清除缓存的实现
    }
    
    func setHandlerCallback(handlerCallback: HandlerCallback) {
        self.handlerCallback = handlerCallback
    }
    
    func getCurrentState(remoteDevice: IRRemote) -> String {
        guard let tvAdapter = uiConfigAdapter as? TVControllerConfigAdapter else {
            L.d(tag, "Invalid adapter type")
            return ""
        }
        return tvAdapter.getCurrentState()
    }
    
    func getCurrentIRDeviceType() -> Int {
        return IRType.DEVICE_REMOTE_TV
    }
    
    // MARK: - Private Methods
    private func postCommand(hub3DeviceId: String, command: String) {
        CHIRManager.shared.irCodeEmit(hub3DeviceId: hub3DeviceId, code: command,irDeviceUUID: "", irType: getCurrentIRDeviceType()) { result in
            switch result {
            case .success(let data):
                L.d(self.tag, "emitIRRemoteDeviceKey success \(data)")
            case .failure(let error):
                L.d(self.tag, "emitIRRemoteDeviceKey error :\(error.localizedDescription)")
            }
        }
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
    
    private func buildCommand(item: IrControlItem, remoteDevice: IRRemote) -> String {
        do {
            guard let configAdapter = uiConfigAdapter as? TVControllerConfigAdapter else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid adapter type"])
            }
            
            let key = configAdapter.paramsSwapper.getTVKey(item.type)
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
}
