//
//  RemoteRepository.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import UIKit
import SesameSDK

/// 红外远程控制器
class RemoteRepository {
    // MARK: - Private Properties
    private var uiConfigAdapter: UIConfigAdapter!
    private var handlerConfigAdapter: HandlerConfigAdapter!
    private var haveInitialized = false
    
    private let tag = String(describing: RemoteRepository.self)
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Public Methods
    
    /// 初始化远程控制器
    /// - Parameters:
    ///   - type: 远程控制器类型
    ///   - uiItemCallback: UI配置更新回调
    ///   - handlerCallback: 按键处理回调
    func initialize(type: Int, uiItemCallback: ConfigUpdateCallback, handlerCallback: HandlerCallback) {
        guard let factory = RemoteAdapterFactoryManager.getFactory(type: type) else {
            L.d(tag, "Failed to create factory for type: \(type)")
            return
        }
        uiConfigAdapter = factory.createUIConfigAdapter()
        handlerConfigAdapter = factory.createHandlerConfigAdapter(uiConfigAdapter: uiConfigAdapter)
        
        uiConfigAdapter.setConfigUpdateCallback(uiItemCallback: uiItemCallback)
        
        haveInitialized = true
        clearHandlerCache()
        clearConfigCache()
        L.d(tag, "RemoteRepository initialized")
    }
    
    /// 加载界面配置
    /// - Parameter completion: 完成回调
    func loadUIConfig(completion: @escaping ConfigResult<UIControlConfig>) {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "RemoteRepository not initialized"])))
            return
        }
        
        uiConfigAdapter.loadConfig(completion: completion)
    }
    
    /// 加载界面参数
    /// - Parameter completion: 完成回调
    func loadUIParams(completion: @escaping ConfigResult<[IrControlItem]>) {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "RemoteRepository not initialized"])))
            return
        }
        
        uiConfigAdapter.loadUIParams(completion: completion)
    }
    
    /// 处理按键点击事件
    /// - Parameters:
    ///   - item: 点击的按键
    ///   - device: hub3宿主
    ///   - remoteDevice: 遥控器设备
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            return
        }
        
        let handleSuccess = uiConfigAdapter.handleItemClick(item: item, device: device, remoteDevice: remoteDevice)
        if handleSuccess {
            handlerConfigAdapter.handleItemClick(item: item, device: device, remoteDevice: remoteDevice)
        }
    }
    
    /// 清除配置缓存
    func clearConfigCache() {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            return
        }
        uiConfigAdapter.clearConfigCache()
    }
    
    /// 清除处理器缓存
    func clearHandlerCache() {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            return
        }
        handlerConfigAdapter.clearHandlerCache()
    }
    
    /// 获取当前状态
    func getCurrentState(hub3: CHHub3, remoteDevice: IRRemote) -> String {
        if(!haveInitialized) {
            return remoteDevice.state ?? ""
        }
        return handlerConfigAdapter.getCurrentState(device: hub3, remoteDevice: remoteDevice)
    }
    
    /// 获取当前设备类型
    func getCurrentIRDeviceType() -> Int {
        return handlerConfigAdapter.getCurrentIRDeviceType()
    }
    
    /// 修改遥控设备信息
    func modifyRemoteIrDeviceInfo(device: CHHub3, remoteDevice: IRRemote, onResponse: @escaping SesameSDK.CHResult<CHEmpty>) {
        handlerConfigAdapter.modifyIRDeviceInfo(device: device, remoteDevice: remoteDevice, onResponse: onResponse)
    }
    
    /// 匹配遥控设备
    func matchRemoteDevice(irRemote: IRRemote) {
        uiConfigAdapter.matchRemoteDevice(irRemote: irRemote)
    }
    
    /// 设置当前状态
    func setCurrentState(_ state: String?) {
        uiConfigAdapter.setCurrentState(state)
    }
    
    /// 获取UI配置适配器
    func getUiConfigAdapter() -> UIConfigAdapter {
        return uiConfigAdapter
    }
    
    /// 获取品牌列表
    func getCompanyCodeList(completion: @escaping ConfigResult<[IRCompanyCode]>) {
        uiConfigAdapter.getCompanyCodeList(completion: completion)
    }
    
    /// 获取匹配UI项列表
    func getMatchUiItemList() -> [IrControlItem] {
        return uiConfigAdapter.getMatchUiItemList()
    }
    
    /// 获取匹配项
    func getMatchItem(position: Int, items: [IrControlItem]) -> IrControlItem? {
        return uiConfigAdapter.getMatchItem(position: position, items: items)
    }
    
    /// 初始化匹配参数
    func initMatchParams() {
        uiConfigAdapter.initMatchParams()
    }
    
    func getIrRemoteType(_ irRemote:IRRemote,_ completion: @escaping (String) -> Void) {
        uiConfigAdapter.getIrRemoteType(irRemote, completion)
    }
}

// MARK: - Error Handling Helper
private extension RemoteRepository {
    func checkInitialization() throws {
        guard haveInitialized else {
            L.d(tag, "RemoteRepository not initialized")
            throw NSError(domain: "",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "RemoteRepository not initialized"])
        }
    }
}
