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

    func initDevices() {
        guard let backgroundContext = backgroundContext else {
            L.d("🤢 初始化現有設備資料失敗")
            return
        }
        do {
            cacheDevices = try backgroundContext.fetch(CHDeviceMO.fetchRequest())
        } catch {
            L.d(error)
        }
    }

    private init() {
        let modelURL = Bundle(for: CHDeviceCenter.self).url(forResource: "CHDeviceModel", withExtension: "momd")
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
    
    func dbURL() throws -> URL {
        let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentDirectory.appendingPathComponent("CHDeviceModel.sqlite")
    }

    func appendDevice(_ CHDeviceKey: CHDeviceKey) {
        guard let backgroundContext = backgroundContext else {
            L.d("🤢 appendDevice failed")
            return
        }
        let devicetoCoreData = CHDeviceMO(context: backgroundContext)
        devicetoCoreData.deviceUUID = CHDeviceKey.deviceUUID.uuidString
        devicetoCoreData.deviceModel = CHDeviceKey.deviceModel
        devicetoCoreData.historyTag = CHDeviceKey.historyTag
        devicetoCoreData.keyIndex = CHDeviceKey.keyIndex
        devicetoCoreData.secretKey = CHDeviceKey.secretKey
        devicetoCoreData.sesame2PublicKey = CHDeviceKey.sesame2PublicKey
        deleteDevice(devicetoCoreData)//避免相同的deviceid 在 db裡面
        cacheDevices.append(devicetoCoreData)
        saveifNeed()
    }
    
    // MARK: - Search
    func getDevice(deviceID: UUID?) -> CHDeviceMO?{
        for bleDevice in self.cacheDevices where bleDevice.deviceUUID == deviceID?.uuidString {
            return bleDevice
        }
        return nil
    }
    
    // MARK: - Delete
    func deleteDevice(_ deviceUUID: UUID?) {
        cacheDevices.forEach({
            if $0.deviceUUID == deviceUUID?.uuidString
            {
                backgroundContext?.delete($0)
            }
        })
        saveifNeed()
    }

    func deleteDevice(_ device: CHDeviceMO) {
        cacheDevices.forEach({
            if $0.deviceUUID == device.deviceUUID
            {
                backgroundContext?.delete($0)
            }
        })
        saveifNeed()
    }
    
    // MARK: - Utils
    func saveifNeed() {
        guard let backgroundContext = backgroundContext else {
            L.d("[core data]🤢 logout failed")
            return
        }
        if backgroundContext.hasChanges {
            try? backgroundContext.save()
        }
    }
    
    func lastCachedevices() -> [CHDeviceMO] {
        // widget 不共享快取。需重新獲取資料庫
        let request: NSFetchRequest<CHDeviceMO> = CHDeviceMO.fetchRequest()
        cacheDevices = (try? backgroundContext?.fetch(request)) ?? [CHDeviceMO]()
        return cacheDevices
    }
    
    func logout() {
        guard let backgroundContext = backgroundContext else {
            L.d("🤢 logout failed")
            return
        }
        cacheDevices = try! backgroundContext.fetch(CHDeviceMO.fetchRequest())
        cacheDevices.forEach({
            backgroundContext.delete($0)
        })
        cacheDevices.removeAll()
        saveifNeed() //注意
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
}
