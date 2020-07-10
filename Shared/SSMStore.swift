//
//  SSMStore.swift
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

class SSMStore: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = SSMStore {
        
    }

    var managedObjectContext: NSManagedObjectContext
    var persistentContainer: NSPersistentContainer
    
    init(completionClosure: @escaping () -> ()) {
        
        let modelURL = Bundle(for: SSMStore.self).url(forResource: "SesameUI", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        self.persistentContainer = NSPersistentContainer(name: "SesameUI", managedObjectModel: model!)
        
        if let appGroup = CHConfiguration.shared.appGroup(),
            let storeURL = URL.storeURL(for: appGroup, databaseName: "SesameUI") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
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
    
    func FRCOfSSM(offset: Int = 0, limit: Int = 0) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request: NSFetchRequest<SSMPropertyMO> = SSMPropertyMO.fetchRequest()
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
    
    func FRCOfSSMHistory(_ ssm: CHSesame2, batchSize: Int) -> NSFetchedResultsController<NSFetchRequestResult> {
            let historyFRC = FRCOfSSMHistory(ssm)
            historyFRC.fetchRequest.fetchBatchSize = batchSize
            return historyFRC
        }
    
    func FRCOfSSMHistory(_ ssm: CHSesame2, offset: Int = 0, limit: Int = 0) -> NSFetchedResultsController<NSFetchRequestResult> {
        let historyFRC = FRCOfSSMHistory(ssm)
        historyFRC.fetchRequest.fetchOffset = offset
        historyFRC.fetchRequest.fetchLimit = limit
        return historyFRC
    }
    
    fileprivate func FRCOfSSMHistory(_ ssm: CHSesame2) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request: NSFetchRequest<SSMHistoryMO> = SSMHistoryMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", ssm.deviceId as CVarArg)
        let sortByName = NSSortDescriptor(key: "timeStamp", ascending: true)
        let sortByIdentity = NSSortDescriptor(key: "sectionIdentifier", ascending: true)
        request.sortDescriptors = [sortByIdentity, sortByName]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                 managedObjectContext: managedObjectContext,
                                                                 sectionNameKeyPath: "sectionIdentifier",
                                                                 cacheName: nil)
        return fetchedResultsController as! NSFetchedResultsController<NSFetchRequestResult>
    }
    
    // MARK: - Functions
    
    func addHistorys(_ historys: [Sesame2History], toDevice device: CHSesame2) {
        let property = getPropertyForDevice(device)
        for history in historys {
            let timeStamp = Int64(history.timeStamp)
            let newHistory = SSMHistoryMO(context: managedObjectContext)
            newHistory.deviceID = device.deviceId
            newHistory.historyTag = history.historyTag
            newHistory.timeStamp = timeStamp
            newHistory.historyType = Int64(history.type.rawValue)
            newHistory.enableCount = Int64(history.enableCount ?? -1)
            newHistory.sectionIdentifier = Date(timeIntervalSince1970: TimeInterval(timeStamp)).toYMD()
            property.addToHistorys(newHistory)
        }
    }
    
    func getHistoryForDevice(_ device: CHSesame2) -> [SSMHistoryMO]? {
        let request: NSFetchRequest<SSMHistoryMO> = SSMHistoryMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId as CVarArg)
        return try? managedObjectContext.fetch(request)
    }
    
    func savePropertyForDevice(_ device: CHSesame2, withProperties properties: [String: Any]) {
        var ssmStore: SSMPropertyMO!
        
        if let ssm = getDevicePropertyFromDBForDevice(device) {
            ssmStore = ssm
        } else {
            let ssm = createPropertyForDeviceWithoutSaving(device)
            ssmStore = ssm
        }
        
        for key in properties.keys {
            ssmStore.setValue(properties[key], forKey: key)
        }
        
        saveIfNeeded()
    }
    
    func createPropertyForDevices(_ devices: [CHSesame2]) {
        for device in devices {
            createPropertyForDeviceWithoutSaving(device)
        }
    }
    
    @discardableResult
    private func createPropertyForDeviceWithoutSaving(_ device: CHSesame2) -> SSMPropertyMO {
        let request: NSFetchRequest<SSMPropertyMO> = SSMPropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId.uuidString as CVarArg)
        let foundProperties = (try? managedObjectContext.fetch(request)) ?? [SSMPropertyMO]()
        if foundProperties.count == 0 {
            let property = SSMPropertyMO(context: managedObjectContext)
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
        deleteHistorysForDevice(device)
    }
    
    func deleteHistorysForDevice(_ device: CHSesame2) {
        if let historys = getHistoryForDevice(device) {
            for history in historys {
                managedObjectContext.delete(history)
            }
        }
        if managedObjectContext.hasChanges {
            try? managedObjectContext.save()
        }
    }
    
    func getPropertyForDevice(_ device: CHSesame2) -> SSMPropertyMO {
        if let property = getDevicePropertyFromDBForDevice(device) {
            return property
        } else {
            return createPropertyForDeviceWithoutSaving(device)
        }
    }
    
    func getDevicePropertyFromDBForDevice(_ device: CHSesame2) -> SSMPropertyMO? {
        let request: NSFetchRequest<SSMPropertyMO> = SSMPropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId.uuidString as CVarArg)
        let devices = (try? managedObjectContext.fetch(request)) ?? [SSMPropertyMO]()
        if let foundDevice = devices.first {
            return foundDevice
        } else {
            return nil
        }
    }
}
