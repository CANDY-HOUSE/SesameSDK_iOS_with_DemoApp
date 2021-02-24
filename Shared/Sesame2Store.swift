//
//  Sesame2Store.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/25.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
#if os(iOS)
import SesameSDK
import AdSupport
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

class Sesame2Store: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = Sesame2Store { }

    private var propertyObjectContext: NSManagedObjectContext?

    lazy var persistentContainer: NSPersistentContainer = {
        let modelURL = Bundle(for: Sesame2Store.self).url(forResource: "SesameUI", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        let persistentContainer = NSPersistentContainer(name: "SesameUI", managedObjectModel: model!)
        
        if let storeURL = URL.storeURL(for: "group.candyhouse.widget", databaseName: "SesameUI") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.setOption(FileProtectionType.none as NSObject, forKey: NSPersistentStoreFileProtectionKey)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return persistentContainer
    }()
    
    let queue = DispatchQueue(label: "thread-safe-obj", qos: .userInteractive)
    
    private var memoryCache = [SesameDeviceMO]()
    
    init(completionClosure: @escaping () -> ()) {
        super.init()
        self.propertyObjectContext = self.persistentContainer.viewContext
    }
    
    func refreshDB() {
        queue.sync() {
            self.memoryCache.removeAll()
            self.propertyObjectContext?.stalenessInterval = 0
            self.propertyObjectContext?.refreshAllObjects()
            self.propertyObjectContext?.stalenessInterval = -1
        }
    }
    
    // MARK: - Save
    func removeAttribute(_ attribute: String, for device: CHDevice) {
        guard let store = propertyFor(device) else {
            return
        }
        store.setValue(nil, forKey: attribute)
        save()
    }
    
    func saveAttributes(_ attributes: [String: Any], for device: CHDevice) {
        guard let store = propertyFor(device) else {
            return
        }
        for key in attributes.keys {
            store.setValue(attributes[key], forKey: key)
        }
        save()
    }
    
    // MARK: - Get or Create
    func propertyFor(_ device: CHDevice) -> SesameDeviceMO? {
        var deviceMO: SesameDeviceMO?
        queue.sync() {
            if let property = memoryCache.filter({ $0.deviceID == device.deviceId }).first {
                deviceMO = property
            } else if let property = getPropertyById(device.deviceId.uuidString) {
                self.memoryCache.append(property)
                deviceMO = property
            } else if let property = createCHDeviceProperty(device) {
                self.memoryCache.append(property)
                deviceMO = property
            }
        }
        return deviceMO
    }
    
    // MARK: - Get
    func getPropertyById(_ deviceId: String) -> SesameDeviceMO? {
        let request: NSFetchRequest<Sesame2PropertyMO> = Sesame2PropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", deviceId as CVarArg)
        if let device = fetch(request as! NSFetchRequest<SesameDeviceMO>)?.first {
            return device
        }
        let botRequest: NSFetchRequest<SesameBotPropertyMO> = SesameBotPropertyMO.fetchRequest()
        botRequest.predicate = NSPredicate(format: "deviceID == %@", deviceId as CVarArg)
        if let device = fetch(botRequest as! NSFetchRequest<SesameDeviceMO>)?.first {
            return device
        }
        let bikeRequest: NSFetchRequest<SesameBotPropertyMO> = SesameBotPropertyMO.fetchRequest()
        bikeRequest.predicate = NSPredicate(format: "deviceID == %@", deviceId as CVarArg)
        if let device = fetch(bikeRequest as! NSFetchRequest<SesameDeviceMO>)?.first {
            return device
        }
        let wm2Request: NSFetchRequest<WifiModule2PropertyMO> = WifiModule2PropertyMO.fetchRequest()
        wm2Request.predicate = NSPredicate(format: "deviceID == %@", deviceId as CVarArg)
        if let device = fetch(wm2Request as! NSFetchRequest<SesameDeviceMO>)?.first {
            return device
        }
        return nil
    }

    @discardableResult
    fileprivate func createCHDeviceProperty(_ device: CHDevice) -> SesameDeviceMO? {
        if let sesame2 = device as? CHSesame2 {
            guard let propertyObjectContext = propertyObjectContext else { return nil }
            let property = Sesame2PropertyMO(context: propertyObjectContext)
            property.deviceID = sesame2.deviceId
            insert(property)
            return property
        } else if let sesameBot = device as? CHSesameBot {
            guard let propertyObjectContext = propertyObjectContext else { return nil }
            let property = SesameBotPropertyMO(context: propertyObjectContext)
            property.deviceID = sesameBot.deviceId
            insert(property)
            return property
        } else if let bikeLock = device as? CHSesameBike {
            guard let propertyObjectContext = propertyObjectContext else { return nil }
            let property = BikeLockPropertyMO(context: propertyObjectContext)
            property.deviceID = bikeLock.deviceId
            insert(property)
            return property
        } else if let wifiModule2 = device as? CHWifiModule2 {
            guard let propertyObjectContext = propertyObjectContext else { return nil }
            let property = WifiModule2PropertyMO(context: propertyObjectContext)
            property.deviceID = wifiModule2.deviceId
            insert(property)
            return property
        } else {
            return nil
        }
    }
    
    // MARK: - Delete
    func deletePropertyFor(_ device: CHDevice) {
        if let storeDevice = getPropertyById(device.deviceId.uuidString) {
            delete(storeDevice)
        }
        queue.async() {
            self.memoryCache.removeAll(where: { $0.deviceID == device.deviceId })
        }
    }
    
    private func fetch(_ request: NSFetchRequest<SesameDeviceMO>) -> [SesameDeviceMO]? {
        return try? self.propertyObjectContext?.fetch(request)
    }
    
    private func save() {
        propertyObjectContext?.performAndWait {
            if self.propertyObjectContext?.hasChanges == true {
                try? self.propertyObjectContext?.save()
            }
        }
    }
    
    private func insert(_ object: NSManagedObject) {
        propertyObjectContext?.performAndWait {
            self.propertyObjectContext?.insert(object)
            if self.propertyObjectContext?.hasChanges == true {
                try? self.propertyObjectContext?.save()
            }
        }
    }
    
    private func delete(_ object: NSManagedObject) {
        propertyObjectContext?.performAndWait {
            self.propertyObjectContext?.delete(object)
            if self.propertyObjectContext?.hasChanges == true {
                try? self.propertyObjectContext?.save()
            }
        }
    }
}

extension Sesame2Store {
    func setHistoryTag(_ historyTag: String?) {
        if let historyTagData = historyTag?.data(using: .utf8) {
            let historyTag = (historyTagData.count > 21) ? historyTagData[0...20] : historyTagData
            UserDefaults.standard.setValue(historyTag, forKey: "historyTag")
        }
    }
    
    func setHistoryTag(_ historyTag: Data) {
        let tag = (historyTag.count > 21) ? historyTag[0...20] : historyTag
        UserDefaults.standard.setValue(tag, forKey: "historyTag")
    }
    
    func getHistoryTagString() -> String {
        if let historyTag = UserDefaults.standard.value(forKey: "historyTag") as? Data {
            return String(decoding: historyTag, as: UTF8.self)
        } else {
            return "co.candyhouse.sesame2.unknownUser".localized
        }
    }
    
    func getHistoryTag() -> Data {
        if let historyTag = UserDefaults.standard.value(forKey: "historyTag") as? Data {
            return historyTag
        } else {
            return "\("co.candyhouse.sesame2.unknownUser".localized)".data(using: .utf8)!
        }
    }
}
