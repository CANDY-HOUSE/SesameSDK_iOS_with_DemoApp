//
//  SesameDeviceList+Control.swift
//  SesameUI
//
//  Created by eddy on 2024/10/8.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

protocol CellSubItemDiscriptor {
    var title: String { get }
    func iconWithDevice(_ device: CHDevice) -> String?
}

private struct Bot2ScriptDisplayItem: CellSubItemDiscriptor {
    let title: String
    let icon: String?

    func iconWithDevice(_ device: CHDevice) -> String? {
        return icon
    }

    func convertToCellDescriptorModel(device: CHDevice, cellCls: AnyClass, click: (() -> Void)?) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            guard let emitCell = cell as? Hub3IREmitCell else { return }
            emitCell.clickHandler = click
            emitCell.device = device
            emitCell.configure(item: self)
        }
    }
}


extension SesameDeviceListViewController {
    
    func handleSubItems(_ cellRow: Int, _ device: CHDevice) -> (dataSource: [CHCellDescriptor], indexPaths: [IndexPath]) {
        var rowIndex = cellRow
        if let hub3 = device as? CHHub3 {
            let irRemotes = hub3.stateInfo?.remoteList ?? []
            guard irRemotes.isEmpty == false else {
                return ([], [])
            }
            var indexPaths = [IndexPath]()
            let irItems = irRemotes.enumerated().map{(index, val) -> CHCellDescriptor in
                rowIndex += 1
                indexPaths.append(IndexPath(row: rowIndex, section: 0))
                return val.convertToCellDescriptorModel(device: device, cellCls:Hub3IREmitCell.self)
            }
            return (irItems, indexPaths)
        } else if let bot2 = device as? CHSesameBot2 {
            let items = getBot2ScriptItems(bot2)
            guard items.isEmpty == false else { return ([], []) }

            var indexPaths = [IndexPath]()
            let irItems = items.compactMap { item -> CHCellDescriptor? in
                guard let index = UInt8(item.actionIndex) else { return nil }
                rowIndex += 1
                indexPaths.append(IndexPath(row: rowIndex, section: 0))

                let titleItem = Bot2ScriptDisplayItem(
                    title: item.alias ?? "🎬 \(index)",
                    icon: device.currentStatusImage() + "-noBorder"
                )

                return titleItem.convertToCellDescriptorModel(device: device, cellCls: Hub3IREmitCell.self) {
                    (device as? CHSesameBot2)?.click(index: index, historytag: device.hisTag, result: { _ in })
                }
            }
            return (irItems, indexPaths)
        }
        return ([], [])
    }
    
    func handleHub3Expandable(_ indexPath: IndexPath) -> Bool {
        guard let device = tableViewProxy.dataSource[safe: indexPath.row]?.rawValue as? CHDevice else {
            return false
        }
        let (irItems, indexPaths) = handleSubItems(indexPath.row, device)
        if let bot2 = device as? CHSesameBot2 {
            expandedBotDeviceId = bot2.deviceId.uuidString
            expandedBotItems = getBot2ScriptItems(bot2)
            expandedBotIndexPaths = indexPaths
        } else {
            expandedBotDeviceId = nil
            expandedBotItems = []
            expandedBotIndexPaths = []
        }
        guard irItems.first != nil else {
            return true
        }
        tableViewProxy.registCells(irItems.first!.cellCls)
        tableViewProxy.tableView.performBatchUpdates {
            if !device.preference.expanded {
                tableViewProxy.dataSource.insert(contentsOf: irItems, at: indexPath.row + 1)
                tableViewProxy.tableView.insertRows(at: indexPaths, with: .automatic)
            } else {
                tableViewProxy.dataSource.removeSubrange(indexPath.row + 1...indexPaths.last!.row)
                tableViewProxy.tableView.deleteRows(at: indexPaths, with: .automatic)
                if device is CHSesameBot2 {
                    expandedBotDeviceId = nil
                    expandedBotItems = []
                    expandedBotIndexPaths = []
                }
            }
        }
        return true
    }
    
    func toggleIndexPathForHub3(_ tapdDevice: CHDevice, _ fast: Bool = false) {
        guard tapdDevice.preference.isExpandable && !isDraggingCell else { return }
        if let index = tableViewProxy.dataSource.firstIndex(where: { ($0.rawValue as? CHDevice)?.deviceId.uuidString == tapdDevice.deviceId.uuidString }) {
            if handleHub3Expandable(.init(row: index, section: 0)) {
                tapdDevice.preference.expanded.toggle()
                if let cell = tableViewProxy.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? Sesame5ListCell {
                    cell.triggerExpand(tapdDevice.preference.expanded)
                }
            }
        }
    }
    
    func isExpandable(_ device: CHDevice) -> Bool {
        if let hub3 = device as? CHHub3 {
            return true
        }
        if let bot2 = device as? CHSesameBot2 {
            if bot2.scripts.eventLength > 0 { return true }
            if let remote = bot2.stateInfo?.scriptList, remote.isEmpty == false { return true }
        }
        return false
    }
    
    func rebuildData() {
        let customDiscriptors = self.devices.map { item -> CHCellDescriptor in
            if item is CHHub3, !item.multicastDelegate.containsDelegate(self) {
                item.multicastDelegate.addDelegate(self)
            }
            item.preference = DevicePreference(isExpandable: isExpandable(item), expanded: false, selectIndex: -1)
            return item.convertToCellDescriptorModel(cellCls: Sesame5ListCell.self) { [self] tapdDevice in
                guard tapdDevice.preference.isExpandable else { return }
                toggleIndexPathForHub3(tapdDevice)
            }
        }
        executeOnMainThread {
            self.tableViewProxy.handleSuccessfulDataSource(nil, customDiscriptors)
        }
    }
    
    private func getBot2ScriptItems(_ bot2: CHSesameBot2) -> [BotScriptItem] {
        let deviceUUID = bot2.deviceId.uuidString

        if bot2.scripts.events.isEmpty == false {
            return bot2.scripts.events.enumerated().map { index, event in
                let fallback = String(data: Data(event.name), encoding: .utf8) ?? "\(index)"
                let alias = BotScriptStore.shared.getAlias(deviceUUID: deviceUUID, actionIndex: index) ?? fallback
                let order = BotScriptStore.shared.getDisplayOrder(deviceUUID: deviceUUID, actionIndex: index) ?? index
                return BotScriptItem(
                    actionIndex: "\(index)",
                    alias: alias,
                    displayOrder: order,
                    isDefault: nil
                )
            }.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
        }

        if let remote = bot2.stateInfo?.scriptList, remote.isEmpty == false {
            return remote.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
        }

        return []
    }
}

extension SesameDeviceListViewController: CHDeviceStatusAndKeysDelegate {
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String : String]) {
        guard device.productModel == .hub3 else {
            return
        }
        debouncer.debounce {
            executeOnMainThread { [self] in
                self.rebuildData()
            }
        }
    }
}

extension SesameDeviceListViewController {
    
    override func allowChangingRow(atIndex indexPath: IndexPath) -> Bool {
        if isDraggingCell { return false }

        // 如果当前展开的是 bot 子列表，只允许拖动 bot 子项范围
        if let _ = expandedBotDeviceId {
            return expandedBotIndexPaths.contains(indexPath)
        }

        let existExpanded = devices.first(where: { $0.preference.expanded == true })
        if existExpanded == nil {
            return super.allowChangingRow(atIndex: indexPath)
        }

        return false
    }
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        guard newIndex != currentIndex else { return }

        if expandedBotIndexPaths.contains(currentIndex),
           expandedBotIndexPaths.contains(newIndex) {
            let from = currentIndex.row - expandedBotIndexPaths.first!.row
            let to = newIndex.row - expandedBotIndexPaths.first!.row
            guard from >= 0, from < expandedBotItems.count,
                  to >= 0, to < expandedBotItems.count else { return }

            let movedObject = expandedBotItems[from]
            expandedBotItems.remove(at: from)
            expandedBotItems.insert(movedObject, at: to)
            return
        }

        let movedObject = devices[currentIndex.row]
        devices.remove(at: currentIndex.row)
        devices.insert(movedObject, at: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        guard finalIndex != initialIndex else { return }
        
        // bot 子列表排序完成
        if expandedBotIndexPaths.contains(initialIndex),
           expandedBotIndexPaths.contains(finalIndex),
           let deviceId = expandedBotDeviceId,
           let bot2 = devices.first(where: { $0.deviceId.uuidString == deviceId }) as? CHSesameBot2 {
            let targetDeviceId = deviceId
            
            // 1. 更新本地缓存
            let metaMap = Dictionary(uniqueKeysWithValues:
                                        expandedBotItems.enumerated().compactMap { order, item -> (Int, BotScriptStore.ScriptMeta)? in
                guard let idx = Int(item.actionIndex) else { return nil }
                return (
                    idx,
                    BotScriptStore.ScriptMeta(
                        alias: BotScriptStore.shared.getAlias(deviceUUID: deviceId, actionIndex: idx),
                        displayOrder: order
                    )
                )
            }
            )
            BotScriptStore.shared.merge(deviceUUID: deviceId, data: metaMap)
            
            // 2. 批量上传 displayOrder
            let batchOrders = expandedBotItems.enumerated().compactMap { order, item -> BotScriptItem? in
                guard Int(item.actionIndex) != nil else { return nil }
                return BotScriptItem(
                    actionIndex: item.actionIndex,
                    alias: nil,
                    displayOrder: order,
                    isDefault: nil
                )
            }
            
            let req = BotScriptRequest(
                deviceUUID: deviceId.uppercased(),
                actionIndex: nil,
                alias: nil,
                isDefault: nil,
                actionData: nil,
                displayOrder: nil,
                deleteAll: nil,
                batchDisplayOrders: batchOrders
            )
            
            CHAPIClient.shared.updateBotScript(req) { [weak self] result in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    guard let self = self else { return }
                    
                    self.rebuildData()
                    
                    guard let row = self.devices.firstIndex(where: { $0.deviceId.uuidString == targetDeviceId }),
                          let targetBot = self.devices[row] as? CHSesameBot2 else {
                        return
                    }
                    targetBot.preference.expanded = false
                    
                    if self.handleHub3Expandable(IndexPath(row: row, section: 0)) {
                        targetBot.preference.expanded = true
                        
                        if let cell = self.tableViewProxy.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? Sesame5ListCell {
                            cell.triggerExpand(true)
                        }
                    }
                }
            }
            
            return
        }
        
        // 原有设备排序逻辑
        isDraggingCell = true
        for (index, device) in devices.enumerated() {
            device.setRank(level: -index)
        }
        
        let newKeys = CHAWSMobileClient.shared.getLocalUserKeys()
        CHAPIClient.shared.postCHUserKeys(newKeys.toData()) { [weak self] result in
            guard let self = self else { return }
            self.isDraggingCell = false
            switch result {
            case .success(_):
                self.rebuildData()
            case .failure(_):
                DispatchQueue.main.async {
                    let movedObject = self.devices[finalIndex.row]
                    self.devices.remove(at: finalIndex.row)
                    self.devices.insert(movedObject, at: initialIndex.row)
                    self.rebuildData()
                }
            }
        }
    }

}
