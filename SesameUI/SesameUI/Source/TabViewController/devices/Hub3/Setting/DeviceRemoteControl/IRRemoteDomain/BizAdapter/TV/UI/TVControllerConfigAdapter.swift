//
//  TVControllerConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import UIKit
import SesameSDK


class TVControllerConfigAdapter: UIConfigAdapter {
    
    private let tag = "TVControllerConfigAdapter"
    private var config: UIControlConfig?
    private var updateCallback: ConfigUpdateCallback?
    private var isMatched: Bool = false
    private var irTable: [[UInt]] = []
    private var irRow: [UInt] = []
    private var specialIrRow: [UInt] = []
    private var currentCode: Int = -1
    private var currentState: String = ""
    
    // 特殊代码常量
    private enum SpecialCode {
        static let sharpCode = 13709
        static let sharpCodeRelocation = 13710
        static let xiaomiCode = 12937
        static let xiaomiCodeRelocation = 12936
    }
    
    private func setupTable() {
        guard let fileURL = Bundle.main.url(forResource: "tv_table", withExtension: "json") else {
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
            let result = BaseUtils.loadJsonObject("tv_control_config", result: &config)
            
            executeOnMainThread {
                if result, let config = config {
                    self?.config = config
                    completion(.success(config))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load config"])))
                }
            }
        }
    }
    
    func loadUIParams(completion: @escaping ConfigResult<[IrControlItem]>) {
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
    
    func setConfigUpdateCallback(uiItemCallback: ConfigUpdateCallback) {
        self.updateCallback = uiItemCallback
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
            let result = BaseUtils.loadJsonArray("tv_conpany_code", result: &companyCodeList)
            
            executeOnMainThread {
                if result {
                    completion(.success(companyCodeList))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load company codes"])))
                }
            }
        }
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
                type: .volumeUp,
                title: NSLocalizedString("co.candyhouse.tvremote.volumeUp", comment: ""),
                iconRes: "",
                optionCode: ""
            ),
            IrControlItem(
                id: 2,
                type: .volumeDown,
                title: NSLocalizedString("co.candyhouse.tvremote.volumeDown", comment: ""),
                iconRes: "",
                optionCode: ""
            ),
            IrControlItem(
                id: 3,
                type: .mute,
                title: NSLocalizedString("co.candyhouse.tvremote.mute", comment: ""),
                iconRes: "",
                optionCode: ""
            )
        ]
    }
    
    func getMatchItem(position: Int, items: [IrControlItem]) -> IrControlItem? {
        switch position {
        case 0: return getItemByType(.powerStatusOn, items: items)
        case 1: return getItemByType(.volumeUp, items: items)
        case 2: return getItemByType(.volumeDown, items: items)
        case 3: return getItemByType(.mute, items: items)
        default: return nil
        }
    }
    
    private func getItemByType(_ type: ItemType, items: [IrControlItem]) -> IrControlItem? {
        return items.first { $0.type == type }
    }
    
    func initMatchParams() {
        // 实现初始化匹配参数的逻辑
    }
    
    func handleItemClick(item: IrControlItem, device: CHHub3, remoteDevice: IRRemote) -> Bool {
        return true // TV控制器不需要特殊处理点击事件
    }
    
    private func createControlItems(config: UIControlConfig) -> [IrControlItem] {
        return config.controls.map { controlConfig in
            let type = ItemType(rawValue: controlConfig.type) ?? .powerStatusOn
            return IrControlItem(
                id: controlConfig.id,
                type: type,
                title: controlConfig.titles[0].localized,
                value: "",
                isSelected: true,
                iconRes: "",
                optionCode: controlConfig.operateCode
            )
        }
    }
    
    func getCurrentState() -> String {
        return currentState
    }
    
    func getTableRow(_ item: IrControlItem, code: Int) -> [UInt] {
        if(isMatched) {
            if(irTable.isEmpty) {
                setupTable()
            }
        } else {
            if(irRow.isEmpty && irTable.isEmpty) {
                setupTable()
            }
        }
        if(code >= irTable.count) {
            L.d(tag,"setupTable Error ! irTable.cout= \(irTable.count) code=\(code)")
            return irRow
        }
        
        if irRow.isEmpty || code != currentCode {
            currentCode = code
            irRow = irTable[code]
            // 处理特殊情况
            if code == SpecialCode.sharpCode {
                specialIrRow = irTable[SpecialCode.sharpCodeRelocation]
            } else if code == SpecialCode.xiaomiCode {
                specialIrRow = irTable[SpecialCode.xiaomiCodeRelocation]
            }
        }
        
        if !isMatched {
            irTable.removeAll()
        }
        
        // 处理特殊情况的返回值
        if code == SpecialCode.sharpCode && item.type == .home && !specialIrRow.isEmpty {
            return specialIrRow
        } else if code == SpecialCode.xiaomiCode &&
                  (item.type != .powerStatusOn && item.type != .powerStatusOff) &&
                  !specialIrRow.isEmpty {
            return specialIrRow
        }
        
        return irRow
    }
    
    func setCurrentState(_ state: String?) {
        currentState = state ?? ""
    }
    
    func getIrRemoteType(_ irRemote: SesameSDK.IRRemote,_ completion: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            var irRemoteList: [IRRemote] = []
            let result = BaseUtils.loadJsonArray("tv_control_type", result: &irRemoteList)
            
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
