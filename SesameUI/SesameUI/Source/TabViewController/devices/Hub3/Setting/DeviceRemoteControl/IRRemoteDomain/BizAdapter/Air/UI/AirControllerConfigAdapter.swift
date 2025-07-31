//
//  AirControllerConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

/**
 每个模式下有不同的风速、摆风、温度等控制项；后续需要扩展出一个列表来。
 当前按键更新结束后，需要更新界面。并且需要同步到服务器和其他界面。
 */

import Foundation
import UIKit
import SesameSDK


class AirControllerConfigAdapter: UIConfigAdapter {
    private let tag = String(describing: AirControllerConfigAdapter.self)
    private var config: UIControlConfig?
    private var updateCallback: ConfigUpdateCallback?
    private var currentTemperature: Int = 25
    
    private var isPowerOn: Bool = false
    private var currentModeIndex: Int = 1
    private var currentFanSpeedIndex: Int = 0
    private var currentVerticalSwingIndex: Int = 0
    private var currentSwingSwitchIndex: Int = 0
    private var currentState: String = ""
    
    // MARK: - UIConfigAdapter Protocol
    
    func loadConfig(completion: @escaping ConfigResult<UIControlConfig>) {
        if config == nil {
            var loadedConfig: UIControlConfig?
            guard BaseUtils.loadJsonObject("air_control_config", result: &loadedConfig) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load config"])))
                return
            }
            config = loadedConfig
        }
        
        if let config = config {
            completion(.success(config))
        } else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Config is null"])))
        }
    }
    
    func loadUIParams(completion: @escaping ConfigResult<[IrControlItem]>) {
        guard let config = config else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Config is null"])))
            return
        }
        let items = createControlItems(config)
        completion(.success(items))
    }
    
    func clearConfigCache() {
        config = nil
    }
    
    func setConfigUpdateCallback(uiItemCallback: ConfigUpdateCallback) {
        updateCallback = uiItemCallback
    }
    
    func matchRemoteDevice(irRemote: IRRemote) {
        L.d(tag, "matchRemoteDevice: irRemote \(irRemote)")
        
        // 如果不是空调设备或已有code，直接返回
        if irRemote.type != IRDeviceType.DEVICE_REMOTE_AIR || irRemote.code > 0 {
            return
        }
        
        // 在后台线程加载和处理数据
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 获取空调类型列表
            var irTypeList: [IRRemote] = []
            guard BaseUtils.loadJsonArray("air_control_type", result: &irTypeList) else {
                L.d(self.tag, "Failed to load air control type list")
                return
            }
            
            // 先尝试通过model匹配
            if self.matchByModel(irRemote: irRemote, irTypeList: irTypeList) {
                return
            }
            
            // 如果model匹配失败，尝试通过state匹配
            if !self.matchByState(irRemote: irRemote, irTypeList: irTypeList) {
                L.d(self.tag, "matchRemoteDevice: failed to match remote device")
            }
        }
    }
    
    func setCurrentState(_ state: String?) {
        guard let state = state, !state.isEmpty else {
            return
        }
        currentState = state
        updateUIConfig()
    }
    
    func getCompanyCodeList(completion: @escaping ConfigResult<[IRCompanyCode]>) {
        // 实现从 R.raw.air_conpany_code 加载数据
        DispatchQueue.global().async {
            var companyCodeList: [IRCompanyCode] = []
            let result = BaseUtils.loadJsonArray("air_conpany_code", result: &companyCodeList)
            
            executeOnMainThread {
                if result {
                    completion(.success(companyCodeList))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load company codes"])))
                }
            }
        }
    }
    
    // MARK: - Match Methods
    
    func getMatchUiItemList() -> [IrControlItem] {
        var list: [IrControlItem] = []
        
        // Power On
        list.append(IrControlItem(
            id: 0,
            type: .powerStatusOn,
            title: NSLocalizedString("co.candyhouse.airKey.on", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Mode Auto
        list.append(IrControlItem(
            id: 1,
            type: .mode,
            title: NSLocalizedString("co.candyhouse.airKey.mode1", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Hot Mode
        list.append(IrControlItem(
            id: 2,
            type: .mode,
            title: NSLocalizedString("co.candyhouse.airKey.mode5", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Cold Mode
        list.append(IrControlItem(
            id: 3,
            type: .mode,
            title: NSLocalizedString("co.candyhouse.airKey.mode2", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Temperature
        list.append(IrControlItem(
            id: 4,
            type: .temperatureValue,
            title: NSLocalizedString("co.candyhouse.airKey.temperature", comment: "") + ":26°C",
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Fan Speed
        list.append(IrControlItem(
            id: 5,
            type: .fanSpeed,
            title: NSLocalizedString("co.candyhouse.airKey.windRate4", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        
        // Power Off
        list.append(IrControlItem(
            id: 6,
            type: .powerStatusOff,
            title: NSLocalizedString("co.candyhouse.airKey.off", comment: ""),
            value: "",
            isSelected: false,
            iconRes: "",
            optionCode: ""
        ))
        return list
    }
    
    
    func getMatchItem(position: Int, items: [IrControlItem]) -> IrControlItem? {
        switch position {
        case 0:
            return items[0]
        case 1: // 自动模式
            setModeIndex(4)
            return items[4]
        case 2: // 制热模式
            setModeIndex(3)
            return items[4]
        case 3: // 制冷模式
            setModeIndex(0)
            return items[4]
        case 4: // 温度
            setTemperature(25)
            return items[3]
        case 5: // 最大风量
            setFanSpeedIndex(2)
            return items[6]
        case 6:
            return items[2]
        default:
            return nil
        }
    }
    
    func initMatchParams() {
        setPower(false)
        setTemperature(25)
        setModeIndex(1)
        setFanSpeedIndex(2)
    }
    
    // MARK: - Helper Methods
    
    private func updateUIConfig() {
        let air = AirProcessor()
        guard air.parseAirData(currentState) else {
            L.d(tag, "updateUIConfig: failed to parse state")
            return
        }
        
        isPowerOn = getPower(air)
        currentTemperature = getTemperature(air)
        currentModeIndex = getModeIndex(air)
        currentFanSpeedIndex = getFanSpeedIndex(air)
        currentVerticalSwingIndex = getVerticalSwingIndex(air)
        currentSwingSwitchIndex = getHorizontalSwingIndex(air)
        
        L.d(tag, """
            updateUIConfig: isPowerOn \(isPowerOn), 
            currentTemperature \(currentTemperature), 
            currentModeIndex \(currentModeIndex), 
            currentFanSpeedIndex \(currentFanSpeedIndex), 
            currentVerticalSwingIndex \(currentVerticalSwingIndex), 
            currentSwingSwitchIndex \(currentSwingSwitchIndex)
            """)
        
        if let config = config {
            let items = createControlItems(config)
            L.d(tag, "updateUIConfig: items.size \(items.count)")
            items.forEach { item in
                updateCallback?.onItemUpdate(item)
            }
        }
    }
    
    // MARK: - Item Click Handling
    
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) -> Bool {
        switch item.type {
        case .powerStatusOn:
            isPowerOn = true
            togglePowerOn(item: item, device: device)
            togglePowerOff(device: device)
            
        case .powerStatusOff:
            isPowerOn = false
            togglePowerOn(device: device)
            togglePowerOff(item: item, device: device)
            
        case .tempControlAdd:
            return adjustTemperatureAdd(item: item, device: device)
            
        case .tempControlReduce:
            return adjustTemperatureReduce(item: item, device: device)
            
        case .mode:
            cycleMode(item: item, device: device)
            
        case .fanSpeed:
            cycleFanSpeed(item: item, device: device)
            
        case .swingVertical:
            cycleVerticalSwing(item: item, device: device)
            
        case .swingHorizontal:
            cycleSwingSwitch(item: item, device: device)
            
        default:
            L.d(tag, "Unknown item type")
        }
        return true
    }
    
    // MARK: - Power Control Methods
    
    private func togglePowerOn(device: CHHub3) {
        let resId = isPowerOn ? 0 : 1
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "POWER_STATUS_ON" }) else {
            return
        }
        
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .powerStatusOn,
            title: controlConfig.titles.isEmpty ? "" : controlConfig.titles[resId].localized,
            value: controlConfig.defaultValue,
            isSelected: isItemSelected(type: .powerStatusOn),
            iconRes: controlConfig.icons.isEmpty ? "" : controlConfig.icons[resId],
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func togglePowerOn(item: IrControlItem, device: CHHub3) {
        let resId = isPowerOn ? 0 : 1
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "POWER_STATUS_ON" }) else {
            return
        }
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: item.title.localized,
            value: item.value,
            isSelected: isItemSelected(type: .powerStatusOn),
            iconRes:controlConfig.icons.isEmpty ? "" : controlConfig.icons[resId],
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func togglePowerOff(device: CHHub3) {
        let resId = isPowerOn ? 0 : 1
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "POWER_STATUS_OFF" }) else {
            return
        }
        
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .powerStatusOff,
            title: controlConfig.titles.isEmpty ? "" : controlConfig.titles[resId].localized,
            value: controlConfig.defaultValue,
            isSelected: isItemSelected(type: .powerStatusOff),
            iconRes: controlConfig.icons.isEmpty ? "" : controlConfig.icons[resId],
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func togglePowerOff(item: IrControlItem, device: CHHub3) {
        let resId = isPowerOn ? 0 : 1
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "POWER_STATUS_OFF" }) else {
            return
        }
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: item.title.localized,
            value: item.value,
            isSelected: isItemSelected(type: .powerStatusOff),
            iconRes: controlConfig.icons.isEmpty ? "" : controlConfig.icons[resId],
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    // MARK: - Temperature Control Methods
    
    private func adjustTemperatureAdd(item: IrControlItem, device: CHHub3) -> Bool {
        guard checkConfig() else { return false }
        
        guard canAdjustTemperature() else {
            BaseUtils.showToast(message: "co.candyhouse.hub3.air_temperature_refuse_change".localized)
            return false
        }
        
        guard let settings = config?.settings.temperature,
              let controlConfig = config?.controls.first(where: { $0.type == "TEMPERATURE_VALUE" }) else {
            return false
        }
        
        currentTemperature = min(settings.max, currentTemperature + settings.step)
        
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .temperatureValue,
            title: getTemperatureString(currentTemperature),
            value: getValueForType(type: .temperatureValue),
            isSelected: isItemSelected(type: .temperatureValue),
            iconRes: "",
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
        return true
    }
    
    private func getTemperatureString(_ temperature: Int) -> String {
        return temperature.description + "°C"
    }
    
    private func adjustTemperatureReduce(item: IrControlItem, device: CHHub3) -> Bool {
        guard checkConfig() else { return false }
        
        guard canAdjustTemperature() else {
            BaseUtils.showToast(message: "air_conditioner_temperature_refuse_change".localized)
            return false
        }
        
        guard let settings = config?.settings.temperature,
              let controlConfig = config?.controls.first(where: { $0.type == "TEMPERATURE_VALUE" }) else {
            return false
        }
        
        currentTemperature = max(settings.min, currentTemperature - settings.step)
        
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .temperatureValue,
            title: getTemperatureString(currentTemperature),
            value: getValueForType(type: .temperatureValue),
            isSelected: isItemSelected(type: .temperatureValue),
            iconRes: "",
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
        return true
    }
    
    // MARK: - Fan and Swing Control Methods
    
    private func cycleFanSpeed(item: IrControlItem, device: CHHub3) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "FAN_SPEED" }) else {
            return
        }
        
        currentFanSpeedIndex = (currentFanSpeedIndex + 1) % itemConfig.icons.count
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: itemConfig.titles.isEmpty ? "" :itemConfig.titles[currentFanSpeedIndex].localized,
            value: item.value,
            isSelected: false,
            iconRes: itemConfig.icons.isEmpty ? "" :itemConfig.icons[currentFanSpeedIndex],
            optionCode: item.optionCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func cycleVerticalSwing(item: IrControlItem, device: CHHub3) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "SWING_VERTICAL" }) else {
            return
        }
        
        currentVerticalSwingIndex = (currentVerticalSwingIndex + 1) % itemConfig.icons.count
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: itemConfig.titles.isEmpty ? "" : itemConfig.titles[currentVerticalSwingIndex].localized,
            value: item.value,
            isSelected: false,
            iconRes: itemConfig.icons.isEmpty ? "" : itemConfig.icons[currentVerticalSwingIndex],
            optionCode: item.optionCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func cycleSwingSwitch(item: IrControlItem, device: CHHub3) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "SWING_HORIZONTAL" }) else {
            return
        }
        
        currentSwingSwitchIndex = (currentSwingSwitchIndex + 1) % itemConfig.icons.count
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: itemConfig.titles.isEmpty ? "" : itemConfig.titles[currentSwingSwitchIndex].localized,
            value: item.value,
            isSelected: false,
            iconRes: itemConfig.icons.isEmpty ? "" : itemConfig.icons[currentSwingSwitchIndex],
            optionCode: item.optionCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    // MARK: - Create Control Items
    
    private func createControlItems(_ config: UIControlConfig) -> [IrControlItem] {
        return config.controls.map { controlConfig in
            let type = ItemType(rawValue: controlConfig.type) ?? .power
            let currentIndex = getCurrentIndexForType(type: type)
            
            switch type {
            case .temperatureValue:
                return IrControlItem(
                    id: controlConfig.id,
                    type: type,
                    title: getTemperatureString(currentTemperature),
                    value: getValueForType(type: type),
                    isSelected: isItemSelected(type: type),
                    iconRes: "",
                    optionCode: controlConfig.operateCode
                )
                
            case .powerStatusOn, .powerStatusOff:
                return IrControlItem(
                    id: controlConfig.id,
                    type: type,
                    title: controlConfig.titles.isEmpty ? "" : controlConfig.titles[currentIndex].localized,
                    value: getValueForType(type: type),
                    isSelected: isItemSelected(type: type),
                    iconRes: controlConfig.icons.isEmpty ? "" : controlConfig.icons[currentIndex],
                    optionCode: controlConfig.operateCode
                )
                
            default:
                return IrControlItem(
                    id: controlConfig.id,
                    type: type,
                    title: controlConfig.titles.isEmpty ? "" : controlConfig.titles[currentIndex].localized,
                    value: getValueForType(type: type),
                    isSelected: isItemSelected(type: type),
                    iconRes: controlConfig.icons.isEmpty ? "" : controlConfig.icons[currentIndex],
                    optionCode: controlConfig.operateCode
                )
            }
        }
    }
    
    // MARK: - Temperature Adjustment Helper
    
    private func canAdjustTemperature() -> Bool {
        guard checkConfig() else { return false }
        return currentModeIndex == 0 || currentModeIndex == 1 || currentModeIndex == 4
    }
    
    // MARK: - Air Processor Helpers
    
    private func getPower(_ air: AirProcessor) -> Bool {
        return air.mPower == 0x01
    }
    
    private func getTemperature(_ air: AirProcessor) -> Int {
        return air.mTemperature
    }
    
    private func getModeIndex(_ air: AirProcessor) -> Int {
        switch air.mMode {
        case 0x01: return 0
        case 0x02: return 1
        case 0x03: return 2
        case 0x04: return 3
        case 0x05: return 4
        default: return 0
        }
    }
    
    private func getFanSpeedIndex(_ air: AirProcessor) -> Int {
        switch air.mWindRate {
        case 0x01: return 0
        case 0x02: return 1
        case 0x03: return 2
        case 0x04: return 3
        default: return 0
        }
    }
    
    private func getVerticalSwingIndex(_ air: AirProcessor) -> Int {
        switch air.mWindDirection {
        case 0x01: return 0
        case 0x02: return 1
        case 0x03: return 2
        default: return 0
        }
    }
    
    private func getHorizontalSwingIndex(_ air: AirProcessor) -> Int {
        switch air.mAutomaticWindDirection {
        case 0x01: return 0
        case 0x02: return 1
        default: return 0
        }
    }
    
    // MARK: - Mode and Fan Control Methods
    
    private func cycleMode(item: IrControlItem, device: CHHub3) {
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "MODE" }) else {
            return
        }
        
        currentModeIndex = (currentModeIndex + 1) % controlConfig.icons.count
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: controlConfig.titles.isEmpty ? "" :controlConfig.titles[currentModeIndex].localized,
            value: item.value,
            isSelected: false,
            iconRes: controlConfig.icons.isEmpty ? "" :controlConfig.icons[currentModeIndex],
            optionCode: controlConfig.operateCode
        )
        
        L.d(tag, "cycleMode: newItem is \(newItem)")
        updateCallback?.onItemUpdate(newItem)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentIndexForType(type: ItemType) -> Int {
        switch type {
        case .mode:
            return currentModeIndex
        case .fanSpeed:
            return currentFanSpeedIndex
        case .swingVertical:
            return currentVerticalSwingIndex
        case .swingHorizontal:
            return currentSwingSwitchIndex
        case .powerStatusOn, .powerStatusOff:
            return isPowerOn ? 0 : 1
        default:
            return 0
        }
    }
    
    private func getValueForType(type: ItemType) -> String {
        switch type {
        case .temperatureValue:
            return "\(currentTemperature)°C"
        default:
            return ""
        }
    }
    
    private func isItemSelected(type: ItemType) -> Bool {
        switch type {
        case .powerStatusOn:
            return isPowerOn
        case .powerStatusOff:
            return !isPowerOn
        default:
            return false
        }
    }
    
    private func checkConfig() -> Bool {
        return config != nil && !(config?.controls.isEmpty ?? true)
    }
    
    // MARK: - Match Helper Methods
    
    private func matchByModel(irRemote: IRRemote, irTypeList: [IRRemote]) -> Bool {
        guard let matchedType = irTypeList.first(where: { $0.model == irRemote.model }) else {
            return false
        }
        
        irRemote.code = matchedType.code
        L.d(tag, "matchByModel: matched code \(irRemote.code)")
        return true
    }
    
    private func matchByState(irRemote: IRRemote, irTypeList: [IRRemote]) -> Bool {
        guard let state = irRemote.state,
              let code = convertToDecimal(state),
              let matchedType = irTypeList.first(where: { $0.code == code }) else {
            L.d(tag, "matchByState: failed to match")
            return false
        }
        
        irRemote.code = code
        irRemote.model = matchedType.model
        L.d(tag, "matchByState: matched code \(code), model \(matchedType.model)")
        return true
    }
    
    private func convertToDecimal(_ value: String) -> Int? {
        guard value.count >= 8 else {
            L.d(tag, "convertToDecimal length < 8")
            return nil
        }
        
        let byte2 = value[value.index(value.startIndex, offsetBy: 4)..<value.index(value.startIndex, offsetBy: 6)]
        let byte3 = value[value.index(value.startIndex, offsetBy: 6)..<value.index(value.startIndex, offsetBy: 8)]
        
        guard isValidHex(String(byte2)), isValidHex(String(byte3)) else {
            L.d(tag, "convertToDecimal contains invalid hex")
            return nil
        }
        
        return Int(String(byte2) + String(byte3), radix: 16)
    }
    
    private func isValidHex(_ str: String) -> Bool {
        return str.range(of: "^[0-9A-Fa-f]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Public Getters and Setters
    
    func getPower() -> Bool {
        return isPowerOn
    }
    
    func getModeIndex() -> Int {
        return currentModeIndex
    }
    
    func getFanSpeedIndex() -> Int {
        return currentFanSpeedIndex
    }
    
    func getVerticalSwingIndex() -> Int {
        return currentVerticalSwingIndex
    }
    
    func getHorizontalSwingIndex() -> Int {
        return currentSwingSwitchIndex
    }
    
    func getTemperature() -> Int {
        return currentTemperature
    }
    
    func getCurrentState() -> String {
        return currentState
    }
    
    func setPower(_ isPowerOn: Bool) {
        self.isPowerOn = isPowerOn
    }
    
    func setModeIndex(_ index: Int) {
        self.currentModeIndex = index
    }
    
    func setFanSpeedIndex(_ index: Int) {
        self.currentFanSpeedIndex = index
    }
    
    func setVerticalSwingIndex(_ index: Int) {
        self.currentVerticalSwingIndex = index
    }
    
    func setHorizontalSwingIndex(_ index: Int) {
        self.currentSwingSwitchIndex = index
    }
    
    func setTemperature(_ temperature: Int) {
        self.currentTemperature = temperature
    }
    
    func getIrRemoteType(_ irRemote: SesameSDK.IRRemote,_ completion: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var irRemoteList: [IRRemote] = []
            let result = BaseUtils.loadJsonArray("air_control_type", result: &irRemoteList)
            if result {
                for model in irRemoteList {
                    if irRemote.code == model.code && irRemote.model == model.model {
                        completion(model.alias)
                        return
                    }
                }
            }
            completion("")
        }
    }
}

