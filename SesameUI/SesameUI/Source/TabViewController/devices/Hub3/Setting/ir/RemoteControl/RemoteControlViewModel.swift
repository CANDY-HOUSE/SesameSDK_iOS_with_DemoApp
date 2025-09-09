//
//  RemoteControlViewModel.swift
//  SesameUI
//
//  Created by wuying on 2025/3/25.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
/// 红外遥控器控制逻辑
class RemoteControlViewModel {
    // MARK: - Types
    enum UiState {
        case loading
        case success(items: [IrControlItem], layoutSettings: LayoutSettings, timestamp: Int64)
        case error(Error)
    }
    
    // MARK: - Private Properties
    private let tag = String(describing: RemoteControlViewModel.self)
    private let remoteRepository: RemoteRepository
    private var hub3DeviceId: String = ""
    private var items: [IrControlItem] = []
    private var config: UIControlConfig?
    private var deviceAlias = ""
    
    var uiStateDidChange: ((UiState) -> Void)?
    var isFirstLoadDidChange: ((Bool) -> Void)?
    
    private(set) var irRemote: IRRemote? {
        didSet {
            notifyObservers()
        }
    }
    private var irRemoteObservers: [(IRRemote?) -> Void] = []
    
    private(set) var isFirstLoad: Bool = true {
        didSet {
            isFirstLoadDidChange?(isFirstLoad)
        }
    }
    
    // MARK: - Initialization
    init(remoteRepository: RemoteRepository) {
        self.remoteRepository = remoteRepository
    }
    
    func observeIRRemote(_ handler: @escaping (IRRemote?) -> Void) {
        irRemoteObservers.append(handler)
        handler(irRemote)
    }
    
    private func notifyObservers() {
        irRemoteObservers.forEach { observer in
            observer(irRemote)
        }
    }
    
    // MARK: - Public Methods
    func initConfig(type: Int) {
        let callback = CallbackWrapper { [weak self] item in
            self?.handleItemUpdate(item)
        }
        remoteRepository.initialize(type: type,uiItemCallback: callback, handlerCallback: callback)
        loadInitialState()
    }
    
    func handleItemClick(item: IrControlItem) {
        guard let remoteDevice = getIrRemoteDevice() else { return }
        remoteRepository.handleItemClick(item: item, hub3DeviceId: hub3DeviceId, remoteDevice: remoteDevice)
    }
    
    func setHub3DeviceId (_ deviceId: String) {
        self.hub3DeviceId = deviceId
    }
    
    func getHub3DeviceId() -> String {
        return hub3DeviceId
    }
    
    func setRemoteDevice(_ remoteDevice: IRRemote) {
        self.irRemote = remoteDevice
    }
    
    func setupIrRemoteDeivceInfo() {
        remoteRepository.setCurrentState(irRemote!.state)
    }
    
    func addIRDeviceInfo(completion: @escaping (Bool) -> Void) {
        var state = irRemote!.state
        if(state == "") {
            state = remoteRepository.getCurrentState(remoteDevice: irRemote!)
        }
        let payload = IRDevicePayload(uuid: irRemote!.uuid, model: irRemote!.model, alias: irRemote!.alias, deviceUUID: hub3DeviceId, state: state ?? "", type: irRemote!.type, keys: [], code: irRemote!.code)
        CHIRManager.shared.postIRDevice(hub3DeviceId, payload){ [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                executeOnMainThread {
                    self.irRemote?.haveSave = true
                    completion(true)
                }
                L.d(self.tag, "addIRDeviceInfo success uuid=\(payload.uuid)")
                
            case .failure(let error):
                executeOnMainThread {
                    completion(false)
                }
                L.d(self.tag, "addIRDeviceInfo fail: \(error)")
            }
        }
    }
    
    func modifyRemoteIrDeviceInfo(alias: String, completion: @escaping (Bool) -> Void) {
        guard let irRemote = irRemote?.clone() else { return }
        irRemote.updateAlias(alias)
        remoteRepository.modifyRemoteIrDeviceInfo(hub3DeviceId: hub3DeviceId, remoteDevice: irRemote) { [weak self] result in
            guard let self = self else { return }
            executeOnMainThread {
                switch result {
                case .success:
                    self.irRemote = irRemote
                    completion(true)
                    L.d(self.tag, "modifyRemoteIrDeviceInfo success")
                case .failure(let error):
                    completion(false)
                    L.d(self.tag, "modifyRemoteIrDeviceInfo fail: \(error)")
                }
            }
        }
    }
    
    func getIrRemoteDevice() -> IRRemote? {
        guard let irRemote = irRemote else { return nil }
        let state = remoteRepository.getCurrentState(remoteDevice: irRemote)
        if (state != "") {
            irRemote.updateState(state)
        }
        L.d(tag, "getIrRemoteDevice irRemote=\(irRemote)")
        return irRemote
    }
    
    func markAsLoaded() {
        isFirstLoad = false
    }
    
    // MARK: - Private Methods
    private func loadInitialState() {
        remoteRepository.loadUIConfig { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let config):
                self.config = config
                self.loadUIParams()
                
            case .failure(let error):
                self.uiStateDidChange?(.error(error))
            }
        }
    }
    
    private func loadUIParams() {
        remoteRepository.loadUIParams { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let items):
                self.items = items
                if let config = self.config {
                    self.refreshAllItems(config: config)
                }
                
            case .failure(let error):
                self.uiStateDidChange?(.error(error))
            }
        }
    }
    
    private func refreshAllItems(config: UIControlConfig) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000) * 10 + Int64.random(in: 0..<10)
            self.uiStateDidChange?(.success(
                items: self.items,
                layoutSettings: config.settings.layout,
                timestamp: timestamp
            ))
        }
    }
    
    private func handleItemUpdate(_ item: IrControlItem) {
        guard let config = config, !items.isEmpty else { return }
        
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            refreshAllItems(config: config)
        }
    }
    
    func getDeviceAlias() -> String {
        return deviceAlias
    }
    
    func setDeviceAlias(_ alias: String) {
        deviceAlias = alias
    }
}

struct CallbackWrapper: HandlerCallback, ConfigUpdateCallback {
    private let callback: (IrControlItem) -> Void
    
    init(_ callback: @escaping (IrControlItem) -> Void) {
        self.callback = callback
    }
    
    // HandlerCallback implementation
    func onItemUpdate(item: IrControlItem) {
        callback(item)
    }
    
    // ConfigUpdateCallback implementation
    func onItemUpdate(_ item: IrControlItem) {
        callback(item)
    }
}
