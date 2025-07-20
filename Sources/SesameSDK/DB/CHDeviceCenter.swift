//
//  CHDeviceCenter.swift
//  Sesame2SDK
//
//  Created by tse on 2019/12/14.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import CoreData


class CHDeviceCenter {
    static let shared = CHDeviceCenter()
    var backgroundContext: NSManagedObjectContext?
    var persistentContainer: NSPersistentContainer?
    var cacheDevices: [CHDeviceMO] = []
    
    
    @discardableResult
    func initDevices() -> [CHDeviceMO] {
        backgroundContext?.performAndWait { [weak self] in
            guard let backgroundContext = self?.backgroundContext else {
                L.d("🤢 Failed to initialize existing devices")
                return
            }
            do {
                let fetchRequest: NSFetchRequest<CHDeviceMO> = CHDeviceMO.fetchRequest()
                let devices = try backgroundContext.fetch(fetchRequest)
                self?.cacheDevices = devices
            } catch {
                L.d("Core Data error: \(error)")
            }
        }
        return self.cacheDevices
    }

    private init() {
        // SPM和framework编译模式不同，导致modelURL的获取方式有区别。
        #if SWIFT_PACKAGE
        let modelURL = Bundle.module.url(forResource: "CHDeviceModel", withExtension: "momd")
        #else
        let modelURL = Bundle(for: CHDeviceCenter.self).url(forResource: "CHDeviceModel", withExtension: "momd")
        #endif
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        self.persistentContainer = NSPersistentContainer(name: "CHDeviceCenter", managedObjectModel: model!)
        for entity in self.persistentContainer!.managedObjectModel.entities {
            if entity.renamingIdentifier == "CHDevice" {
                entity.renamingIdentifier = "CandyDevice"
                let deviceUUID = entity.attributesByName["deviceUUID"]
                deviceUUID?.renamingIdentifier = "device_id"
                
                let deviceModel = entity.attributesByName["deviceModel"]
                deviceModel?.renamingIdentifier = "device_model"
                
                break
            }
        }
        let appGroup = CHConfiguration.shared.appGroup
        if let storeURL = URL.storeURL(for: appGroup, databaseName: "CHDeviceModel") { ///設定存儲位置
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            self.persistentContainer?.persistentStoreDescriptions = [storeDescription]
        }
        
        self.persistentContainer?.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                L.d(error)
            }
        })
        self.backgroundContext = self.persistentContainer?.newBackgroundContext()
        initDevices()
    }
    
    func appendDevice(_ CHDeviceKey: CHDeviceKey) {
        appendDevices([CHDeviceKey])
    }
    
    func appendDevices(_ CHDeviceKeys: [CHDeviceKey]) {
        backgroundContext?.performAndWait { [weak self] in
            guard let self = self else { return }
            var tmpMOs = [CHDeviceMO]()
            for deviceKey in CHDeviceKeys {
                if deviceKey.deviceUUID.uuidString.isEmpty { continue }
                let fetchReq = CHDeviceMO.fetchRequest()
                fetchReq.predicate = NSPredicate(format: "deviceUUID == %@", deviceKey.deviceUUID.uuidString as CVarArg)
                do {
                    let results = try self.backgroundContext!.fetch(fetchReq)
                    if let devicetoCoreData = results.first, devicetoCoreData.deviceUUID == deviceKey.deviceUUID.uuidString {
                        // 更新coredata
                        devicetoCoreData.updateDeviceKey(deviceKey)
                        tmpMOs.append(devicetoCoreData)
                    } else {
                        // 创建coredata
                        let newSesame2Coredata = deviceKey.toSesame2CoreData()
                        tmpMOs.append(newSesame2Coredata)
                    }
                } catch let error as NSError {
                    // 错误处理
                    L.d("Could not fetch or save. \(error), \(error.userInfo)")
                }
            }
            if self.backgroundContext!.hasChanges {
                do {
                    try self.backgroundContext!.save()
                    for deviceMO in tmpMOs {
                        if let index = self.cacheDevices.firstIndex(where: { $0.deviceUUID == deviceMO.deviceUUID }) {
                            self.cacheDevices[index].updateDeviceKey(deviceMO)
                        } else {
                            self.cacheDevices.append(deviceMO)
                        }
                    }
                } catch let error as NSError {
                    // 错误处理
                    print("Could not save context. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    // MARK: - Search
    func getDevice(deviceID: UUID?) -> CHDeviceMO? {
        return self.cacheDevices.first { $0.deviceUUID == deviceID?.uuidString }
    }
    
    // MARK: - Delete
    func deleteDevice(_ deviceUUID: UUID?) {
        guard let uuidString = deviceUUID?.uuidString else { return }
        backgroundContext?.performAndWait {
            let devicesToDelete = self.cacheDevices.filter { $0.deviceUUID == uuidString }
            if !devicesToDelete.isEmpty {
                for device in devicesToDelete {
                    self.backgroundContext?.delete(device)
                }
                self.saveifNeed()
                self.cacheDevices.removeAll { $0.deviceUUID == uuidString }
            }
        }
    }

    func deleteDevice(_ device: CHDeviceMO) {
        guard device.deviceUUID?.isEmpty == false else { return }
        deleteDevice(UUID(uuidString: device.deviceUUID!))
    }
    
    // MARK: - Utils
    func saveifNeed() {
        guard let context = self.backgroundContext else { return }
        context.performAndWait {
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                L.d("[core data] Error saving context: \(error)")
            }
        }
    }
    
    func lastCachedevices() -> [CHDeviceMO] {
        // widget 不共享快取。需重新獲取資料庫
        return self.initDevices()
    }
    
    func logout() {
        guard let backgroundContext = backgroundContext else {
            L.d("🤢 logout failed")
            return
        }
        backgroundContext.performAndWait {
            do {
                let devices = try backgroundContext.fetch(CHDeviceMO.fetchRequest())
                devices.forEach { device in
                    backgroundContext.delete(device)
                }
                self.saveifNeed()
                cacheDevices.removeAll()
            } catch let error as NSError {
                L.d("Core Data error: \(error)")
            }
        }
    }
}

extension URL {
    static func storeURL(for appGroup: String?, databaseName: String) -> URL? {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup ?? "groupname") else {
            return nil
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

extension CHDeviceMO {
    func toCHDeviceKey() -> CHDeviceKey {
        let tmp = CHDeviceKey(deviceUUID: UUID(uuidString: self.deviceUUID!)!,
                              deviceModel: self.deviceModel!,
                              historyTag: self.historyTag,
                              keyIndex: self.keyIndex!,
                              secretKey: self.secretKey!,
                              sesame2PublicKey: self.sesame2PublicKey!)

        return tmp
    }
    
    private func ifIgnoreUpdate(_ deviceKey: CHDeviceKey) -> Bool {
        return self.deviceUUID == deviceKey.deviceUUID.uuidString && self.deviceModel == deviceKey.deviceModel && self.historyTag == deviceKey.historyTag && self.keyIndex == deviceKey.keyIndex && self.secretKey == deviceKey.secretKey && self.sesame2PublicKey == deviceKey.sesame2PublicKey
    }
    
    fileprivate func updateDeviceKey(_ deviceKey: CHDeviceKey) {
        guard !ifIgnoreUpdate(deviceKey) else { return }
        self.deviceUUID = deviceKey.deviceUUID.uuidString
        self.deviceModel = deviceKey.deviceModel
        self.historyTag = deviceKey.historyTag
        self.keyIndex = deviceKey.keyIndex
        self.secretKey = deviceKey.secretKey
        self.sesame2PublicKey = deviceKey.sesame2PublicKey
    }
    
    fileprivate func updateDeviceKey(_ deviceKey: CHDeviceMO) {
        self.deviceUUID = deviceKey.deviceUUID
        self.deviceModel = deviceKey.deviceModel
        self.historyTag = deviceKey.historyTag
        self.keyIndex = deviceKey.keyIndex
        self.secretKey = deviceKey.secretKey
        self.sesame2PublicKey = deviceKey.sesame2PublicKey
    }
}
