//
//  SesameDeviceList+Expand.swift
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
            var indexPaths = [IndexPath]()
            let irItems = bot2.scripts.events.enumerated().map{(index, val) -> CHCellDescriptor in
                rowIndex += 1
                indexPaths.append(IndexPath(row: rowIndex, section: 0))
                return val.convertToCellDescriptorModel(device: device, cellCls: Hub3IREmitCell.self) {
                    (device as? CHSesameBot2)?.click(index: UInt8(index), result: { _ in })
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
        if let bot2 = device as? CHSesameBot2, bot2.scripts.eventLength > 0 {
            return true
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
        if(isDraggingCell) {
            return false
        }
        let existExpanded = devices.first(where: { $0.preference.expanded == true })
        if (existExpanded == nil) {
            return super.allowChangingRow(atIndex: indexPath)
        }
        return false
    }
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        guard newIndex != currentIndex else { return }
        let movedObject = devices[currentIndex.row]
        devices.remove(at: currentIndex.row)
        devices.insert(movedObject, at: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        guard finalIndex != initialIndex else { return }
        isDraggingCell = true
        for (index, device) in devices.enumerated() {
            device.setRank(level: -index)
        }
        let newKeys = CHUserAPIManager.shared.getLocalUserKeys().map { (userKey: CHUserKey) -> CHUserKey in
            var userKey = userKey
            userKey.subUUID = CHUserAPIManager.shared.subId
            return userKey
        }
        CHUserAPIManager.shared.postCHUserKeys(newKeys) { [weak self] result in
            guard let self = self else { return }
            self.isDraggingCell = false
            switch result {
                case .success(_):
                    self.rebuildData()
                case .failure(let error):
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
