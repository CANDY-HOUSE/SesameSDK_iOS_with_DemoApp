//
//  LightControllerConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import UIKit
import SesameSDK

class LightControllerConfigAdapter: UIConfigAdapter {
    private let tag = String(describing: LightControllerConfigAdapter.self)
    private var config: UIControlConfig?
    private var updateCallback: ConfigUpdateCallback?
    private var isPowerOn: Bool = false
    private var isMatched: Bool = false
    private var irTable: [[UInt]] = []
    private var irRow: [UInt] = []
    private var currentCode: Int = -1
    private var currentState = ""
    
    private func setupTable() {
        guard let fileURL = Bundle.main.url(forResource: "light_table", withExtension: "json") else {
            L.d("JsonLoader", "tv_table.json not found in bundle")
            return
        }
        do {
            let jsonString = try String(contentsOf: fileURL, encoding: .utf8)
            let rowPattern = "\\[(.*?)\\]"
            let rowRegex = try NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators])
            let rowMatches = rowRegex.matches(in: jsonString, range: NSRange(location: 0, length: jsonString.utf16.count))
            irTable = rowMatches.compactMap { rowMatch -> [UInt]? in
                guard let rowRange = Range(rowMatch.range(at: 1), in: jsonString) else { return nil }
                let rowString = String(jsonString[rowRange])
                let hexPattern = "0[xX][0-9a-fA-F]+"
                let hexRegex = try? NSRegularExpression(pattern: hexPattern, options: [])
                guard let hexMatches = hexRegex?.matches(in: rowString, range: NSRange(location: 0, length: rowString.utf16.count)) else { return nil }
                return hexMatches.compactMap { hexMatch -> UInt? in
                    guard let hexRange = Range(hexMatch.range, in: rowString) else { return nil }
                    let hexString = String(rowString[hexRange])
                    return UInt(String(hexString.dropFirst(2)), radix: 16) // 去除0x前缀
                }
            }
        } catch {
            L.d("JsonLoader", "Error: \(error.localizedDescription)")
            irTable = []
        }
    }
    
    
    func loadConfig(completion: @escaping ConfigResult<UIControlConfig>) {
        if let config = self.config {
            completion(.success(config))
            return
        }
        DispatchQueue.global().async { [weak self] in
            var config: UIControlConfig?
            let result = BaseUtils.loadJsonObject("light_control_config", result: &config)
            executeOnMainThread {
                if result, let config = config {
                    self?.config = config
                    completion(.success(config))
                } else {
                    completion(.failure(NSError(domain: "",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to load config"])))
                }
            }
        }
    }
    
    func loadUIParams(completion: @escaping (Result<[IrControlItem], Error>) -> Void) {
        guard let config = self.config else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Config is null"])))
            return
        }
        
        let items = createControlItems(config: config)
        completion(.success(items))
    }
    
    func clearConfigCache() {
        config = nil
        irTable.removeAll()
        irRow.removeAll()
    }
    
    func matchRemoteDevice(irRemote: IRRemote) {
        guard irRemote.code <= 0,
              let state = irRemote.state,
              !state.isEmpty else {
            return
        }
        
        if let code = convertToDecimal(value: state) {
            irRemote.code = code
        }
    }
    
    private func convertToDecimal(value: String) -> Int? {
        guard value.count >= 8 else {
            L.d(tag, "convertToDecimal length < 8")
            return nil
        }
        
        let startIndex = value.index(value.startIndex, offsetBy: 4)
        let midIndex = value.index(value.startIndex, offsetBy: 6)
        let endIndex = value.index(value.startIndex, offsetBy: 8)
        
        let byte2 = String(value[startIndex..<midIndex])
        let byte3 = String(value[midIndex..<endIndex])
        
        guard isValidHex(str: byte2), isValidHex(str: byte3) else {
            L.d(tag, "convertToDecimal contains invalid hex")
            return nil
        }
        
        return Int(byte2 + byte3, radix: 16)
    }
    
    private func isValidHex(str: String) -> Bool {
        let pattern = "^[0-9A-Fa-f]+$"
        return str.range(of: pattern, options: .regularExpression) != nil
    }
    func getCompanyCodeList(completion: @escaping ConfigResult<[IRCompanyCode]>) {
        DispatchQueue.global().async {
            var companyCodeList: [IRCompanyCode] = []
            let result = BaseUtils.loadJsonArray("light_conpany_code", result: &companyCodeList)
            
            executeOnMainThread {
                if result {
                    completion(.success(companyCodeList))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load company codes"])))
                }
            }
        }
    }
    
    func setConfigUpdateCallback(uiItemCallback: ConfigUpdateCallback) {
        self.updateCallback = uiItemCallback
    }
    
    func setCurrentState(_ state: String?) {
        currentState = state ?? ""
    }
    
    func getMatchUiItemList() -> [IrControlItem] {
        isMatched = true
        return [
            IrControlItem(
                id: 0,
                type: .powerStatusOn,
                title: NSLocalizedString("co.candyhouse.airKey.on", comment: ""),
                iconRes: "",
                optionCode: ""
            ),
            IrControlItem(
                id: 1,
                type: .brightnessUp,
                title: NSLocalizedString("co.candyhouse.light.brightnessUp", comment: ""),
                iconRes: "",
                optionCode: ""
            ),
            IrControlItem(
                id: 2,
                type: .brightnessDown,
                title: NSLocalizedString("co.candyhouse.light.brightnessDown", comment: ""),
                iconRes: "",
                optionCode: ""
            ),
            IrControlItem(
                id: 3,
                type: .powerStatusOff,
                title: NSLocalizedString("co.candyhouse.airKey.off", comment: ""),
                iconRes: "",
                optionCode: ""
            )
        ]
    }
    
    
    func getMatchItem(position: Int, items: [IrControlItem]) -> IrControlItem? {
        switch position {
        case 0: return getItemByType(.powerStatusOn, items: items)
        case 1: return getItemByType(.brightnessUp, items: items)
        case 2: return getItemByType(.brightnessDown, items: items)
        case 3: return getItemByType(.powerStatusOff, items: items)
        default: return nil
        }
    }
    
    private func getItemByType(_ type: ItemType, items: [IrControlItem]) -> IrControlItem? {
        return items.first { $0.type == type }
    }
    
    func initMatchParams() {
       
    }
    
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) -> Bool {
        switch item.type {
        case .powerStatusOn:
            isPowerOn = true
            updatePowerStatus()
            return true
        case .powerStatusOff:
            isPowerOn = false
            updatePowerStatus()
            return true
        default:
            if !isPowerOn {
                // Toast.makeText(context, R.string.tv_power_off_tip, Toast.LENGTH_SHORT).show()
                return false
            }
            return true
        }
    }
    
    private func updatePowerStatus() {
        guard let config = config else { return }
        updatePowerItem(config: config, type: .powerStatusOn)
        updatePowerItem(config: config, type: .powerStatusOff)
    }
    
    private func updatePowerItem(config: UIControlConfig, type: ItemType) {
        guard let controlConfig = config.controls.first(where: { $0.type == type.rawValue }) else { return }
        
        let item = IrControlItem(
            id: controlConfig.id,
            type: type,
            title: controlConfig.titles[0].localized,
            value: "",
            isSelected: type == .powerStatusOn ? isPowerOn : !isPowerOn,
            iconRes: "",
            optionCode: controlConfig.operateCode
        )
        
        updateCallback?.onItemUpdate(item)
    }
    
    private func createControlItems(config: UIControlConfig) -> [IrControlItem] {
        return config.controls.map { controlConfig in
            let type = ItemType(rawValue: controlConfig.type) ?? .powerStatusOn
            return IrControlItem(
                id: controlConfig.id,
                type: type,
                title: controlConfig.titles[0].localized,
                value: "",
                isSelected: type == .powerStatusOn ? isPowerOn : (type == .powerStatusOff ? !isPowerOn : false),
                iconRes: "",
                optionCode: controlConfig.operateCode
            )
        }
    }
    
    func getCurrentState() -> String {
        return currentState
    }
    
    func getTableRow(_ code: Int) -> [UInt] {
        if(isMatched) {
            if(irTable.isEmpty) {
                setupTable()
            }
        } else {
            if(irRow.isEmpty && irTable.isEmpty) {
                setupTable()
            }
        }
        
        if irRow.isEmpty || code != currentCode {
            currentCode = code
            irRow = irTable[code]
        }
        
        if !isMatched {
            irTable.removeAll()
        }
        
        return irRow
    }
    
    func getIrRemoteType(_ irRemote: SesameSDK.IRRemote,_ completion: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var irRemoteList: [IRRemote] = []
            let result = BaseUtils.loadJsonArray("light_control_type", result: &irRemoteList)
            
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
