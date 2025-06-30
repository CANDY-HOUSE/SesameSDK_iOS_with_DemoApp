//
//  Sesame2Store.swift
//  SesameUI
//  [CoreData]
//  Created by YuHan Hsiao on 2020/6/25.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
#if os(iOS)
import SesameSDK
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

/// UI 層 DB
class Sesame2Store: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = Sesame2Store { }

    lazy var propertyObjectContext: NSManagedObjectContext = {
        return  self.persistentContainer.viewContext
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let modelURL = Bundle(for: Sesame2Store.self).url(forResource: "SesameUI", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        let persistentContainer = NSPersistentContainer(name: "SesameUI", managedObjectModel: model!)
        
        if let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.candyhouse.widget") {
            let storeURL = fileContainer.appendingPathComponent("SesameUI.sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.setOption(FileProtectionType.none as NSObject, forKey: NSPersistentStoreFileProtectionKey)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                L.d(error)
            }
        })
        return persistentContainer
    }()
    
    private var memoryCache = NSCache<NSString, SesameDeviceMO>()

    private func cacheDevice(_ device: SesameDeviceMO) {
        memoryCache.setObject(device, forKey: device.deviceID!.uuidString as NSString)
    }

    private func getDeviceFromCache(deviceID: UUID) -> SesameDeviceMO? {
        return memoryCache.object(forKey: deviceID.uuidString as NSString)
    }

    private func removeDeviceFromCache(deviceID: UUID) {
        memoryCache.removeObject(forKey: deviceID.uuidString as NSString)
    }
    
    init(completionClosure: @escaping () -> ()) {
        super.init()
        self.propertyObjectContext = self.persistentContainer.viewContext
    }
    
    func refreshDB() {
        propertyObjectContext.perform {
            self.memoryCache.removeAllObjects()
            self.propertyObjectContext.stalenessInterval = 0
            self.propertyObjectContext.refreshAllObjects()
            self.propertyObjectContext.stalenessInterval = -1
        }
    }
    
    // MARK: - Save
    /// 移除 sesame device 的 某筆資料
    func removeAttribute(_ attribute: String, for device: CHDevice) {
        guard let store = propertyFor(device) else {
            return
        }
        store.setValue(nil, forKey: attribute)
        save()
    }
    
    /// 新增資料給 sesame device
    func saveAttributes(_ attributes: [String: Any], for device: CHDevice) {
        guard let store = propertyFor(device) else {
            L.d("saveAttributes retrn")
            return
        }

        for key in attributes.keys {
            store.setValue(attributes[key], forKey: key)
        }
        save()
    }
    
    // MARK: - Get or Create
    // 用 sesame device 取回 儲存 data model
    func propertyFor(_ device: CHDevice) -> SesameDeviceMO? {
        var deviceMO: SesameDeviceMO?
        if let property = getDeviceFromCache(deviceID: device.deviceId) {
            deviceMO = property
        } else if let property = getPropertyById(device.deviceId.uuidString) {
            cacheDevice(property)
            deviceMO = property
        } else  {
            let property = createCHDeviceProperty(device)
            cacheDevice(property)
            deviceMO = property
        }
        return deviceMO
    }
    
    // MARK: - Get
    // 用 sesame device uuid 取回 儲存 data model
    func getPropertyById(_ deviceId: String) -> SesameDeviceMO? {
        let deviceRequest: NSFetchRequest<SesameDeviceMO> = SesameDeviceMO.fetchRequest()
        deviceRequest.predicate = NSPredicate(format: "deviceID == %@", deviceId as CVarArg)
        if let device = fetch(deviceRequest)?.first {
            return device
        }
        return nil
    }

    @discardableResult
    fileprivate func createCHDeviceProperty(_ device: CHDevice) -> SesameDeviceMO {
        if let sesame2 = device as? CHSesame5 {//todo check 抽象共用
            let property = Sesame2PropertyMO(context: propertyObjectContext)
            property.deviceID = sesame2.deviceId
            insert(property)
            return property
        } else if let sesame2 = device as? CHSesame2 {
            let property = Sesame2PropertyMO(context: propertyObjectContext)
            property.deviceID = sesame2.deviceId
            insert(property)
            return property
        } else if let sesameBot = device as? CHSesameBot {
            let property = SesameBotPropertyMO(context: propertyObjectContext)
            property.deviceID = sesameBot.deviceId
            insert(property)
            return property
        }else {
            let property = SesameDeviceMO(context: propertyObjectContext)
            property.deviceID = device.deviceId
            insert(property)
            return property
            //            return nil
        }
    }
    
    // MARK: - Delete
    func deletePropertyFor(_ device: CHDevice) { // 從UI層DB刪除設備資料
        if let storeDevice = getPropertyById(device.deviceId.uuidString) {
            propertyObjectContext.performAndWait {
                self.propertyObjectContext.delete(storeDevice)
                if self.propertyObjectContext.hasChanges == true {
                    do {
                        try self.propertyObjectContext.save()
                        self.removeDeviceFromCache(deviceID: device.deviceId)
                    } catch {
                        L.d("Error: \(error)")
                    }
                }
            }
        }
    }

    private func fetch(_ request: NSFetchRequest<SesameDeviceMO>) -> [SesameDeviceMO]? {
        var result: [SesameDeviceMO]?
        propertyObjectContext.performAndWait {
            do {
                result = try self.propertyObjectContext.fetch(request)
            } catch let error as NSError {
                L.d("Fetch error: \(error), \(error.userInfo)")
                result = nil
            }
        }
        return result
    }
    
    private func save() {
        propertyObjectContext.performAndWait {
            if self.propertyObjectContext.hasChanges == true {
                try? self.propertyObjectContext.save()
            }
        }
    }
    
    private func insert(_ object: NSManagedObject) {
        propertyObjectContext.performAndWait {
            self.propertyObjectContext.insert(object)
            if self.propertyObjectContext.hasChanges == true {
                try? self.propertyObjectContext.save()
            }
        }
    }
}

extension Sesame2Store {
    /// 儲存 history tag by 字串
    func setHistoryTag(_ historyTag: String?) {
        if let historyTagData = historyTag?.data(using: .utf8) {
            let historyTag = (historyTagData.count > 21) ? historyTagData[0...20] : historyTagData
            UserDefaults.standard.setValue(historyTag, forKey: "historyTag")
        }
    }
    
    /// 儲存 history tag by data
    func setHistoryTag(_ historyTag: Data) {
        let tag = (historyTag.count > 21) ? historyTag[0...20] : historyTag
        UserDefaults.standard.setValue(tag, forKey: "historyTag")
    }
    
    /// 取回 history tag string, 若無則返回預設值
    func getHistoryTagString() -> String {
        if let historyTag = UserDefaults.standard.value(forKey: "historyTag") as? Data {
            return String(decoding: historyTag, as: UTF8.self)
        } else {
            return "co.candyhouse.sesame2.unknownUser".localized
        }
    }
    
    /// 取回 history tag data, 若無則返回預設值
    func getHistoryTag() -> Data {
        if let historyTag = UserDefaults.standard.value(forKey: "historyTag") as? Data {
            return historyTag
        } else {
            return "\("co.candyhouse.sesame2.unknownUser".localized)".data(using: .utf8)!
        }
    }
    
    /// 儲存 sesame gps
    func saveLocationForSesame2(_ sesame2: CHSesameLock, location: CLLocation, radius: CLLocationDistance) {
        saveAttributes(["latitude" : location.coordinate.latitude,
                      "longitude" : location.coordinate.longitude,
                      "radius" : radius], for: sesame2)
    }
    
    /// 取回 sesame gps
    func getLocationForSesame2(_ sesame2: CHSesameLock) -> (CLLocation, CLLocationDistance) {
        let property = propertyFor(sesame2) as! Sesame2PropertyMO
        return (CLLocation(latitude: property.latitude, longitude: property.longitude), property.radius)
    }
    
    func getSubUuid() -> Data {
        if let historyTag = UserDefaults.standard.value(forKey: "cognitoSubuuid") as? Data,
           !historyTag.isEmpty{
            return historyTag
        } else {
            return Data(repeating: 0xff, count: 16) // 未登录用户默认uuid为ffffffffffffffffffffffffffffffff
        }
    }
    
    func setSubUuid(_ subUuid: Data) {
        UserDefaults.standard.setValue(subUuid, forKey: "cognitoSubuuid")
    }


}
