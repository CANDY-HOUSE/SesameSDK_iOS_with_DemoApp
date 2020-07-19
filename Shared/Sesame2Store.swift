//
//  Sesame2Store.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/25.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreData
#if os(iOS)
import SesameSDK
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

class Sesame2Store: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = Sesame2Store {
        
    }

    var managedObjectContext: NSManagedObjectContext
    var persistentContainer: NSPersistentContainer
    
    init(completionClosure: @escaping () -> ()) {
        
        let modelURL = Bundle(for: Sesame2Store.self).url(forResource: "SesameUI", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        self.persistentContainer = NSPersistentContainer(name: "SesameUI", managedObjectModel: model!)
        
        if let storeURL = URL.storeURL(for: "group.candyhouse.widget", databaseName: "SesameUI") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
            self.persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        
        self.persistentContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = self.persistentContainer.newBackgroundContext()
    }
    
    // MARK: - FRC
    
    func FRCOfSesame2(offset: Int = 0, limit: Int = 0) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request: NSFetchRequest<Sesame2PropertyMO> = Sesame2PropertyMO.fetchRequest()
        request.fetchOffset = offset
        request.fetchLimit = limit
        let sortByName = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortByName]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                 managedObjectContext: managedObjectContext,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
        return fetchedResultsController as! NSFetchedResultsController<NSFetchRequestResult>
    }
    
    func FRCOfSesame2History(_ sesame2: CHSesame2, batchSize: Int) -> NSFetchedResultsController<NSFetchRequestResult> {
            let historyFRC = FRCOfSesame2History(sesame2)
            historyFRC.fetchRequest.fetchBatchSize = batchSize
            return historyFRC
        }
    
    func FRCOfSesame2History(_ sesame2: CHSesame2, offset: Int = 0, limit: Int = 0) -> NSFetchedResultsController<NSFetchRequestResult> {
        let historyFRC = FRCOfSesame2History(sesame2)
        historyFRC.fetchRequest.fetchOffset = offset
        historyFRC.fetchRequest.fetchLimit = limit
        return historyFRC
    }
    
    fileprivate func FRCOfSesame2History(_ sesam2: CHSesame2) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request: NSFetchRequest<Sesame2HistoryMO> = Sesame2HistoryMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", sesam2.deviceId as CVarArg)
        let sortByName = NSSortDescriptor(key: "recordID", ascending: true)
        let sortByIdentity = NSSortDescriptor(key: "sectionIdentifier", ascending: true)
        request.sortDescriptors = [sortByIdentity, sortByName]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                 managedObjectContext: managedObjectContext,
                                                                 sectionNameKeyPath: "sectionIdentifier",
                                                                 cacheName: nil)
        return fetchedResultsController as! NSFetchedResultsController<NSFetchRequestResult>
    }
    
    // MARK: - Functions
    
    func addHistories(_ histories: [CHSesame2History], toDevice device: CHSesame2) {
        let property = getPropertyForDevice(device)
        for history in histories {
            switch history {
            case let autoLockUpdatedHistory as Sesame2HistoryAutoLockUpdated:
                let newHistory = Sesame2HistoryAutoLockUpdatedMO(context: managedObjectContext)
                let timeStamp = Int64(autoLockUpdatedHistory.timeStamp)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = autoLockUpdatedHistory.historyTag
                newHistory.timeStamp = timeStamp
                newHistory.historyType = Int64(autoLockUpdatedHistory.type.rawValue)
                newHistory.registrationTimes = Int64(autoLockUpdatedHistory.registrationTimes ?? -1)
                newHistory.recordID = autoLockUpdatedHistory.recordID
                newHistory.sectionIdentifier = Date(timeIntervalSince1970: TimeInterval(timeStamp)).toYMD()
                if let enableBefore = autoLockUpdatedHistory.enabledBefore {
                    newHistory.enabledBefore = Int64(enableBefore)
                }
                if let enableAfter = autoLockUpdatedHistory.enabledAfter {
                    newHistory.enabledAfter = Int64(enableAfter)
                }
                property.addToHistories(newHistory)
            case let mechSettingUpdatedHistory as Sesame2HistoryMechSettingUpdated:
                let newHistory = Sesame2HistoryMechSettingUpdatedMO(context: managedObjectContext)
                let timeStamp = Int64(mechSettingUpdatedHistory.timeStamp)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = mechSettingUpdatedHistory.historyTag
                newHistory.timeStamp = timeStamp
                newHistory.historyType = Int64(mechSettingUpdatedHistory.type.rawValue)
                newHistory.registrationTimes = Int64(mechSettingUpdatedHistory.registrationTimes ?? -1)
                newHistory.recordID = mechSettingUpdatedHistory.recordID
                newHistory.sectionIdentifier = Date(timeIntervalSince1970: TimeInterval(timeStamp)).toYMD()
                if let lockRangeMaxAfter = mechSettingUpdatedHistory.lockRangeMaxAfter {
                    newHistory.lockRangeMaxAfter = Int64(lockRangeMaxAfter)
                }
                
                if let lockRangeMaxBefore = mechSettingUpdatedHistory.lockRangeMaxBefore {
                    newHistory.lockRangeMaxBefore = Int64(lockRangeMaxBefore)
                }
                
                if let lockRangeMinAfter = mechSettingUpdatedHistory.lockRangeMinAfter {
                    newHistory.lockRangeMinAfter = Int64(lockRangeMinAfter)
                }
                
                if let lockRangeMinBefore = mechSettingUpdatedHistory.lockRangeMinBefore {
                    newHistory.lockRangeMinBefore = Int64(lockRangeMinBefore)
                }
                
                if let lockTargetAfter = mechSettingUpdatedHistory.lockTargetAfter {
                    newHistory.lockTargetAfter = Int64(lockTargetAfter)
                }
                
                if let lockTargetBefore = mechSettingUpdatedHistory.lockTargetBefore {
                    newHistory.lockTargetBefore = Int64(lockTargetBefore)
                }
                
                if let unlockRangeMaxAfter = mechSettingUpdatedHistory.unlockRangeMaxAfter {
                    newHistory.unlockRangeMaxAfter = Int64(unlockRangeMaxAfter)
                }
                
                if let unlockRangeMaxBefore = mechSettingUpdatedHistory.unlockRangeMaxBefore {
                    newHistory.unlockRangeMaxBefore = Int64(unlockRangeMaxBefore)
                }
                
                if let unlockRangeMinAfter = mechSettingUpdatedHistory.unlockRangeMinAfter {
                    newHistory.unlockRangeMinAfter = Int64(unlockRangeMinAfter)
                }
                
                if let unlockRangeMinBefore = mechSettingUpdatedHistory.unlockRangeMinBefore {
                    newHistory.unlockRangeMinBefore = Int64(unlockRangeMinBefore)
                }
                
                if let unlockTargetAfter = mechSettingUpdatedHistory.unlockTargetAfter {
                    newHistory.unlockTargetAfter = Int64(unlockTargetAfter)
                }
                
                if let unlockTargetBefore = mechSettingUpdatedHistory.unlockTargetBefore {
                    newHistory.unlockTargetBefore = Int64(unlockTargetBefore)
                }
                property.addToHistories(newHistory)
            case let timeChaedHistoryHistory as Sesame2HistoryTimeChanged:
                let newHistory = Sesame2HistoryTimeChangedMO(context: managedObjectContext)
                let timeStamp = Int64(timeChaedHistoryHistory.timeStamp)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = timeChaedHistoryHistory.historyTag
                newHistory.timeStamp = timeStamp
                newHistory.historyType = Int64(timeChaedHistoryHistory.type.rawValue)
                newHistory.registrationTimes = Int64(timeChaedHistoryHistory.registrationTimes ?? -1)
                newHistory.recordID = history.recordID
                newHistory.sectionIdentifier = Date(timeIntervalSince1970: TimeInterval(timeStamp)).toYMD()
                newHistory.newTime = timeChaedHistoryHistory.newTime
                newHistory.timeBefore = timeChaedHistoryHistory.timeBefore
                property.addToHistories(newHistory)
            case let lockUnlockHistory as Sesame2HistoryLockUnlock:
                let newHistory = Sesame2HistoryLockUnlockMO(context: managedObjectContext)
                let timeStamp = Int64(lockUnlockHistory.timeStamp)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = lockUnlockHistory.historyTag
                newHistory.timeStamp = timeStamp
                newHistory.historyType = Int64(lockUnlockHistory.type.rawValue)
                newHistory.registrationTimes = Int64(lockUnlockHistory.registrationTimes ?? -1)
                newHistory.recordID = lockUnlockHistory.recordID
                newHistory.sectionIdentifier = Date(timeIntervalSince1970: TimeInterval(timeStamp)).toYMD()
                property.addToHistories(newHistory)
            default:
                break
            }
        }
    }
    
    func getHistoriesForDevice(_ device: CHSesame2) -> [Sesame2HistoryMO]? {
        let request: NSFetchRequest<Sesame2HistoryMO> = Sesame2HistoryMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId as CVarArg)
        return try? managedObjectContext.fetch(request)
    }
    
    func savePropertyForDevice(_ device: CHSesame2, withProperties properties: [String: Any]) {
        var sesame2Store: Sesame2PropertyMO!
        
        if let sesame2 = getDevicePropertyFromDBForDevice(device) {
            sesame2Store = sesame2
        } else {
            let sesame2 = createPropertyForDeviceWithoutSaving(device)
            sesame2Store = sesame2
        }
        
        for key in properties.keys {
            sesame2Store.setValue(properties[key], forKey: key)
        }
        
        saveIfNeeded()
    }
    
    func createPropertyForDevices(_ devices: [CHSesame2]) {
        for device in devices {
            createPropertyForDeviceWithoutSaving(device)
        }
    }
    
    @discardableResult
    private func createPropertyForDeviceWithoutSaving(_ device: CHSesame2) -> Sesame2PropertyMO {
        let request: NSFetchRequest<Sesame2PropertyMO> = Sesame2PropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId.uuidString as CVarArg)
        let foundProperties = (try? managedObjectContext.fetch(request)) ?? [Sesame2PropertyMO]()
        if foundProperties.count == 0 {
            let property = Sesame2PropertyMO(context: managedObjectContext)
            property.deviceID = device.deviceId
            return property
        } else {
            return foundProperties.first!
        }
    }
    
    func saveIfNeeded() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch  {
                L.d("save error",error)
            }
        }
    }
    
    func deletePropertyForDevice(_ device: CHSesame2) {
        let storeDevice = getPropertyForDevice(device)
        managedObjectContext.delete(storeDevice)
        // TODO: Replace by cascade delete
        deleteHistoriesForDevice(device)
    }
    
    func deleteHistoriesForDevice(_ device: CHSesame2) {
        if let histories = getHistoriesForDevice(device) {
            for history in histories {
                managedObjectContext.delete(history)
            }
        }
        if managedObjectContext.hasChanges {
            try? managedObjectContext.save()
        }
    }
    
    func getPropertyForDevice(_ device: CHSesame2) -> Sesame2PropertyMO {
        if let property = getDevicePropertyFromDBForDevice(device) {
            return property
        } else {
            return createPropertyForDeviceWithoutSaving(device)
        }
    }
    
    func getDevicePropertyFromDBForDevice(_ device: CHSesame2) -> Sesame2PropertyMO? {
        let request: NSFetchRequest<Sesame2PropertyMO> = Sesame2PropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId.uuidString as CVarArg)
        let devices = (try? managedObjectContext.fetch(request)) ?? [Sesame2PropertyMO]()
        if let foundDevice = devices.first {
            return foundDevice
        } else {
            return nil
        }
    }
}
