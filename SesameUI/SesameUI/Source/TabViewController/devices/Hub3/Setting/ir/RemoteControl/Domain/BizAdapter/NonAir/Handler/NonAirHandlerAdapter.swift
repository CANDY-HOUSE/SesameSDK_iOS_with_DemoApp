//
//  NonAirHandlerAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/9/12.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


/// TV控制器处理适配器
final class NonAirHandlerAdapter: RemoteHandlerAdapter {
    // MARK: - Private Properties
    private let tag = String(describing: NonAirHandlerAdapter.self)
    private let uiAdapter: RemoteUIAdapter
    private var handlerCallback: HandlerCallback?
    private var uiType: RemoteUIType
    
    // MARK: - Initialization
    init(_ uiConfigAdapter: RemoteUIAdapter) {
        self.uiAdapter = uiConfigAdapter
        self.uiType = (uiConfigAdapter as? NonAirUIAdapter)!.uiType
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
            executeOnMainThread { self.uiAdapter.setCurrentState(command) }
            self.postCommand(hub3DeviceId: hub3DeviceId, command: command)
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
        guard let adapter = uiAdapter as? NonAirUIAdapter else {
            L.d(tag, "Invalid adapter type")
            return ""
        }
        return adapter.getCurrentState()
    }
    
    func getCurrentIRDeviceType() -> Int {
        return uiType.irType
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
            guard let configAdapter = uiAdapter as? NonAirUIAdapter else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid adapter type"])
            }
            
            let key: Int
            switch uiType {
            case .light:
                key = configAdapter.paramsSwapper.getLightKey(item.type)
            case .tv:
                key = configAdapter.paramsSwapper.getTVKey(item.type)
            case .fan:
                key = configAdapter.paramsSwapper.getFanKey(item.type)
            default :
                key = 0
            }
            
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
