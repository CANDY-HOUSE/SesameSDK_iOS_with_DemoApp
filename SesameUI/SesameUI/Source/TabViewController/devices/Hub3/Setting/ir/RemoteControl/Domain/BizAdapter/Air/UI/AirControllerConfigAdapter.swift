//
//  AirControllerConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import UIKit
import SesameSDK


class AirControllerConfigAdapter: UIConfigAdapter {
    
    private let tag = String(describing: AirControllerConfigAdapter.self)
    private var config: UIControlConfig?
    private var updateCallback: ConfigUpdateCallback?
    private var currentState: String = ""
    
    let commandProcessor = HXDCommandProcessor()
    let paramsSwapper = HXDParametersSwapper()
    
    // MARK: - UIConfigAdapter Protocol
    
    func loadConfig(completion: @escaping ConfigResult<UIControlConfig>) {
        if config == nil {
            var loadedConfig: UIControlConfig?
            guard LoadRemoteConfig.loadJsonObject("air_control_config", result: &loadedConfig) else {
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
    
    func setCurrentState(_ state: String?) {
        guard let state = state, !state.isEmpty else {
            return
        }
        currentState = state
        updateUIConfig()
    }
    
    private func updateUIConfig() {
        
        let parseSuccess = commandProcessor.parseAirData(state: currentState)
        guard parseSuccess else {
            L.e(tag, "updateUIConfig: Failed to parse state")
            return
        }
        
        if let config = config {
            let items = createControlItems(config)
            L.d(tag, "updateUIConfig: items.size \(items.count)")
            items.forEach { item in
                updateCallback?.onItemUpdate(item)
            }
        }
    }
    
    // MARK: - Item Click Handling
    
    func handleItemClick(item: IrControlItem, remoteDevice: IRRemote) -> Bool {
        switch item.type {
        case .powerStatusOn:
            commandProcessor.setPower(paramsSwapper.getPowerValue(true))
            togglePowerOn(item: item)
            togglePowerOff()
            
        case .powerStatusOff:
            commandProcessor.setPower(paramsSwapper.getPowerValue(false))
            togglePowerOn()
            togglePowerOff(item: item)
            
        case .tempControlAdd:
            return adjustTemperatureAdd(item: item)
            
        case .tempControlReduce:
            return adjustTemperatureReduce(item: item)
            
        case .mode:
            cycleMode(item: item)
            
        case .fanSpeed:
            cycleFanSpeed(item: item)
            
        case .windDirection:
            cycleVerticalSwing(item: item)
            
        case .autoWindDirection:
            cycleSwingSwitch(item: item)
            
        default:
            L.d(tag, "Unknown item type")
        }
        return true
    }
    
    // MARK: - Power Control Methods
    
    private func togglePowerOn() {
        let resId = paramsSwapper.getPowerIndex(commandProcessor.getPower()) ? 0 : 1
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
    
    private func togglePowerOn(item: IrControlItem) {
        let resId = paramsSwapper.getPowerIndex(commandProcessor.getPower()) ? 0 : 1
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
    
    private func togglePowerOff() {
        let resId = paramsSwapper.getPowerIndex(commandProcessor.getPower()) ? 0 : 1
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
    
    private func togglePowerOff(item: IrControlItem) {
        let resId = paramsSwapper.getPowerIndex(commandProcessor.getPower()) ? 0 : 1
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
    
    private func adjustTemperatureAdd(item: IrControlItem) -> Bool {
        guard checkConfig() else { return false }
        
        guard canAdjustTemperature() else { return false }
        
        guard let settings = config?.settings.temperature,
              let controlConfig = config?.controls.first(where: { $0.type == "TEMPERATURE_VALUE" }) else {
            return false
        }
        
        commandProcessor.setTemperature(min(settings.max, commandProcessor.getTemperature() + settings.step))
       
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .temperatureValue,
            title: getTemperatureString(commandProcessor.getTemperature()),
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
    
    private func adjustTemperatureReduce(item: IrControlItem) -> Bool {
        guard checkConfig() else { return false }
        
        guard canAdjustTemperature() else { return false }
        
        guard let settings = config?.settings.temperature,
              let controlConfig = config?.controls.first(where: { $0.type == "TEMPERATURE_VALUE" }) else {
            return false
        }
        commandProcessor.setTemperature(max(settings.min, commandProcessor.getTemperature() - settings.step))
        
        let newItem = IrControlItem(
            id: controlConfig.id,
            type: .temperatureValue,
            title: getTemperatureString(commandProcessor.getTemperature()),
            value: getValueForType(type: .temperatureValue),
            isSelected: isItemSelected(type: .temperatureValue),
            iconRes: "",
            optionCode: controlConfig.operateCode
        )
        updateCallback?.onItemUpdate(newItem)
        return true
    }
    
    // MARK: - Fan and Swing Control Methods
    
    private func cycleFanSpeed(item: IrControlItem) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "FAN_SPEED" }) else {
            return
        }
        var currentFanSpeedIndex = paramsSwapper.getFanSpeedIndex(commandProcessor.getFanSpeed())
        currentFanSpeedIndex = (currentFanSpeedIndex + 1) % itemConfig.icons.count
        commandProcessor.setFanSpeed(paramsSwapper.getFanSpeedValue(currentFanSpeedIndex))
        
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
    
    private func cycleVerticalSwing(item: IrControlItem) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "SWING_VERTICAL" }) else {
            return
        }
        var windDirectionIndex = paramsSwapper.getWindDirectionIndex(commandProcessor.getWindDirection())
        windDirectionIndex = (windDirectionIndex + 1) % itemConfig.icons.count
        commandProcessor.setWindDirection(paramsSwapper.getWindDirectionValue(windDirectionIndex))
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: itemConfig.titles.isEmpty ? "" : itemConfig.titles[windDirectionIndex].localized,
            value: item.value,
            isSelected: false,
            iconRes: itemConfig.icons.isEmpty ? "" : itemConfig.icons[windDirectionIndex],
            optionCode: item.optionCode
        )
        updateCallback?.onItemUpdate(newItem)
    }
    
    private func cycleSwingSwitch(item: IrControlItem) {
        guard checkConfig(),
              let itemConfig = config?.controls.first(where: { $0.type == "SWING_HORIZONTAL" }) else {
            return
        }
        var autoWindDirection = paramsSwapper.getAutoWindDirectionIndex(commandProcessor.getAutoDirection())
        autoWindDirection = (autoWindDirection + 1) % itemConfig.icons.count
        commandProcessor.setAutoWindDirection(paramsSwapper.getAutoWindDirectionValue(autoWindDirection))
        
        let newItem = IrControlItem(
            id: item.id,
            type: item.type,
            title: itemConfig.titles.isEmpty ? "" : itemConfig.titles[autoWindDirection].localized,
            value: item.value,
            isSelected: false,
            iconRes: itemConfig.icons.isEmpty ? "" : itemConfig.icons[autoWindDirection],
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
                    title: getTemperatureString(commandProcessor.getTemperature()),
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
        let currentModeIndex = paramsSwapper.getModeIndex(commandProcessor.getMode())
        return currentModeIndex == 0 || currentModeIndex == 1 || currentModeIndex == 4
    }
    // MARK: - Mode and Fan Control Methods
    
    private func cycleMode(item: IrControlItem) {
        guard checkConfig(),
              let controlConfig = config?.controls.first(where: { $0.type == "MODE" }) else {
            return
        }
        var currentModeIndex = paramsSwapper.getModeIndex(commandProcessor.getMode())
        currentModeIndex = (currentModeIndex + 1) % controlConfig.icons.count
        commandProcessor.setMode(paramsSwapper.getModeValue(currentModeIndex))
        
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
            return paramsSwapper.getModeIndex(commandProcessor.getMode())
        case .fanSpeed:
            return paramsSwapper.getFanSpeedIndex(commandProcessor.getFanSpeed())
        case .windDirection:
            return paramsSwapper.getWindDirectionIndex(commandProcessor.getWindDirection())
        case .autoWindDirection:
            return paramsSwapper.getAutoWindDirectionIndex(commandProcessor.getAutoDirection())
        case .powerStatusOn, .powerStatusOff:
            return paramsSwapper.getPowerIndex(commandProcessor.getPower()) ? 0 : 1
        default:
            return 0
        }
    }
    
    private func getValueForType(type: ItemType) -> String {
        switch type {
        case .temperatureValue:
            return "\(commandProcessor.getTemperature())°C"
        default:
            return ""
        }
    }
    
    private func isItemSelected(type: ItemType) -> Bool {
        switch type {
        case .powerStatusOn:
            return paramsSwapper.getPowerIndex(commandProcessor.getPower())
        case .powerStatusOff:
            return !paramsSwapper.getPowerIndex(commandProcessor.getPower())
        default:
            return false
        }
    }
    
    private func checkConfig() -> Bool {
        return config != nil && !(config?.controls.isEmpty ?? true)
    }
    
    // MARK: - Public Getters and Setters
    
    func getCurrentState() -> String {
        return currentState
    }
}

