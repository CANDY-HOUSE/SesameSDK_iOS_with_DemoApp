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
    
    // MARK: - Private Constants
    private enum TVKey {
        static let volumeOut = 0x01  // vol-
        static let channelIn = 0x02  // ch+
        static let menu = 0x03       // menu
        static let channelOut = 0x04 // ch-
        static let volumeIn = 0x05   // vol+
        static let power = 0x06      // power
        static let mute = 0x07       // mute
        static let back = 0x14       // back
        static let ok = 0x15         // ok
        static let up = 0x16         // up
        static let left = 0x17       // left
        static let right = 0x18      // right
        static let down = 0x19       // down
        static let home = 0x1A       // home
    }
    
    // MARK: - Initialization
    init(uiConfigAdapter: UIConfigAdapter) {
        self.uiConfigAdapter = uiConfigAdapter
    }
    
    // MARK: - HandlerConfigAdapter Implementation
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let command = self.buildCommand(item: item, remoteDevice: remoteDevice)
            guard !command.isEmpty else {
                L.d(self.tag, "handleItemClick buildCommand is empty!")
                return
            }
            L.d(
                self.tag,
                "handleItemClick buildCommand is:command=\(command), device:\(device.deviceId.uuidString.uppercased())"
            )
            // 更新UI状态
            executeOnMainThread {
                self.uiConfigAdapter.setCurrentState(command)
            }
            // 发送命令
            self.postCommand(device: device, command: command)
            // 更新设备状态
            if !remoteDevice.uuid.isEmpty && remoteDevice.haveSave {
                self.updateDeviceState(device: device, remoteDevice: remoteDevice, command: command)
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
    
    func clearHandlerCache() {
        // 清除缓存的实现
    }
    
    func setHandlerCallback(handlerCallback: HandlerCallback) {
        self.handlerCallback = handlerCallback
    }
    
    func getCurrentState(device: CHHub3, remoteDevice: IRRemote) -> String {
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
    private func postCommand(device: CHHub3, command: String) {
        device.irCodeEmit(id: command,irDeviceUUID: "") { result in
            switch result {
            case .success(let data):
                L.d(self.tag, "emitIRRemoteDeviceKey success \(data)")
            case .failure(let error):
                L.d(self.tag, "emitIRRemoteDeviceKey error :\(error.localizedDescription)")
            }
        }
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
    
    private func buildCommand(item: IrControlItem, remoteDevice: IRRemote) -> String {
        let key = getCurrentKey(item: item)
        
        guard let configAdapter = uiConfigAdapter as? TVControllerConfigAdapter else {
            L.d(tag, "Invalid adapter type")
            return ""
        }
        
        do {
            let row = configAdapter.getTableRow(item, code: remoteDevice.code)
            if (row.count < 7) {
                return ""
            }
            var buf: [UInt8] = []
            
            // 构建命令buffer
            buf.append(0x30)
            buf.append(0x00)
            buf.append(UInt8(row[0]))
            buf.append(UInt8(row[(key - 1) * 2 + 1]))
            buf.append(UInt8(row[(key - 1) * 2 + 2]))
            buf.append(UInt8(row[row.count - 4]))
            buf.append(UInt8(row[row.count - 3]))
            buf.append(UInt8(row[row.count - 2]))
            buf.append(UInt8(row[row.count - 1]))
            
            // 计算校验和
            let checksum = UInt8(buf.reduce(0) { $0 + Int($1) } & 0xFF)
            buf.append(checksum)
            
            return buf.map { String(format: "%02X", $0) }.joined()
        } catch {
            L.d(tag, "Build command failed: \(error)")
            return ""
        }
    }
    
    private func getCurrentKey(item: IrControlItem) -> Int {
        switch item.type {
        case .powerStatusOn, .powerStatusOff:
            return TVKey.power
        case .mute:
            return TVKey.mute
        case .back:
            return TVKey.back
        case .up:
            return TVKey.up
        case .menu:
            return TVKey.menu
        case .left:
            return TVKey.left
        case .ok:
            return TVKey.ok
        case .right:
            return TVKey.right
        case .volumeUp:
            return TVKey.volumeIn
        case .down:
            return TVKey.down
        case .channelUp:
            return TVKey.channelIn
        case .volumeDown:
            return TVKey.volumeOut
        case .home:
            return TVKey.home
        case .channelDown:
            return TVKey.channelOut
        default:
            L.d(tag, "Unknown item type: \(item.type)")
            return TVKey.volumeOut
        }
    }
}
