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
            case .autoLock(let autoLockHistory):
                let newHistory = Sesame2HistoryAutoLockMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = autoLockHistory.historyTag
                newHistory.date = autoLockHistory.date
                newHistory.recordID = autoLockHistory.recordID
                newHistory.sectionIdentifier = autoLockHistory.date.toYMD()
                property.addToHistories(newHistory)
            case .autoLockUpdated(let autoLockUpdatedHistory):
                let newHistory = Sesame2HistoryAutoLockUpdatedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = autoLockUpdatedHistory.historyTag
                newHistory.date = autoLockUpdatedHistory.date
                newHistory.recordID = autoLockUpdatedHistory.recordID
                newHistory.sectionIdentifier = autoLockUpdatedHistory.date.toYMD()
                newHistory.enabledBefore = Int64(autoLockUpdatedHistory.enabledBefore)
                newHistory.enabledAfter = Int64(autoLockUpdatedHistory.enabledAfter)
                property.addToHistories(newHistory)
            case .mechSettingUpdated(let mechSettingUpdatedHistory):
                let newHistory = Sesame2HistoryMechSettingUpdatedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = mechSettingUpdatedHistory.historyTag
                newHistory.date = mechSettingUpdatedHistory.date
                newHistory.recordID = mechSettingUpdatedHistory.recordID
                newHistory.sectionIdentifier = mechSettingUpdatedHistory.date.toYMD()
                newHistory.lockTargetAfter = Int64(mechSettingUpdatedHistory.lockTargetAfter)
                newHistory.lockTargetBefore = Int64(mechSettingUpdatedHistory.lockTargetBefore)
                newHistory.unlockTargetAfter = Int64(mechSettingUpdatedHistory.unlockTargetAfter)
                newHistory.unlockTargetBefore = Int64(mechSettingUpdatedHistory.unlockTargetBefore)
                property.addToHistories(newHistory)
            case .timeChanged(let timeChaedHistoryHistory):
                let newHistory = Sesame2HistoryTimeChangedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = timeChaedHistoryHistory.historyTag
                newHistory.date = timeChaedHistoryHistory.date
                newHistory.recordID = timeChaedHistoryHistory.recordID
                newHistory.sectionIdentifier = timeChaedHistoryHistory.date.toYMD()
                newHistory.newTime = timeChaedHistoryHistory.timeAfter
                newHistory.timeBefore = timeChaedHistoryHistory.timeBefore
                property.addToHistories(newHistory)
            case .bleLock(let lockHistory):
                let newHistory = Sesame2HistoryLockMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = lockHistory.historyTag
                newHistory.date = lockHistory.date
                newHistory.recordID = lockHistory.recordID
                newHistory.sectionIdentifier = lockHistory.date.toYMD()
                property.addToHistories(newHistory)
            case .manualElse(let manualElseHisotry):
                let newHistory = Sesame2HistoryManualElseMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = manualElseHisotry.historyTag
                newHistory.date = manualElseHisotry.date
                newHistory.recordID = manualElseHisotry.recordID
                newHistory.sectionIdentifier = manualElseHisotry.date.toYMD()
                property.addToHistories(newHistory)
            case .manualLocked(let manualLockedHistory):
                let newHistory = Sesame2HistoryManualLockedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = manualLockedHistory.historyTag
                newHistory.date = manualLockedHistory.date
                newHistory.recordID = manualLockedHistory.recordID
                newHistory.sectionIdentifier = manualLockedHistory.date.toYMD()
                property.addToHistories(newHistory)
            case .manualUnlocked(let manualUnlockedHistory):
                let newHistory = Sesame2HistoryManualUnlockedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = manualUnlockedHistory.historyTag
                newHistory.date = manualUnlockedHistory.date
                newHistory.recordID = manualUnlockedHistory.recordID
                newHistory.sectionIdentifier = manualUnlockedHistory.date.toYMD()
                property.addToHistories(newHistory)
            case .bleUnLock(let bleUnLockHistory):
                let newHistory = Sesame2HistoryUnlockMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = bleUnLockHistory.historyTag
                newHistory.date = bleUnLockHistory.date
                newHistory.recordID = bleUnLockHistory.recordID
                newHistory.sectionIdentifier = bleUnLockHistory.date.toYMD()
                property.addToHistories(newHistory)
            case .bleAdvParameterUpdated(let bleAdvUpdatedHistory):
                let newHistory = Sesame2HistoryBleAdvParameterUpdatedMO(context: managedObjectContext)
                newHistory.deviceID = device.deviceId
                newHistory.historyTag = bleAdvUpdatedHistory.historyTag
                newHistory.date = bleAdvUpdatedHistory.date
                newHistory.recordID = bleAdvUpdatedHistory.recordID
                newHistory.sectionIdentifier = bleAdvUpdatedHistory.date.toYMD()
                newHistory.intervalBefore = bleAdvUpdatedHistory.intervalBefore
                newHistory.intervalAfter = bleAdvUpdatedHistory.intervalAfter
                newHistory.dbmBefore = Int64(bleAdvUpdatedHistory.dbmBefore)
                newHistory.dbmAfter = Int64(bleAdvUpdatedHistory.dbmAfter)
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
    
    func deletePropertyAndHisotryForDevice(_ device: CHSesame2) {
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
