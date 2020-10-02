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
#elseif os(watchOS)
import SesameWatchKitSDK
#endif

class Sesame2Store: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = Sesame2Store {
        
    }

    private var propertyObjectContext: NSManagedObjectContext
    private var persistentContainer: NSPersistentContainer
    
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
        self.propertyObjectContext = self.persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Functions
    func savePropertyToDevice(_ device: CHSesame2, withProperties properties: [String: Any]) {
        var sesame2Store: Sesame2PropertyMO!
        
        if let sesame2 = getSesame2Property(device) {
//            L.d("⌚️ get sesame2")
            sesame2Store = sesame2
        } else {
            let sesame2 = createSesame2Property(device)
//            L.d("⌚️ create sesame2")
            sesame2Store = sesame2
        }
        
        for key in properties.keys {
            sesame2Store.setValue(properties[key], forKey: key)
        }
        
        saveIfNeeded()
    }
    
    func saveIfNeeded() {
        
        if propertyObjectContext.hasChanges {
            do {
                try propertyObjectContext.save()
            } catch {
                L.d("save error",error)
            }
//            L.d("⌚️ propertyObjectContext saved")
        }
    }
    
    func deletePropertyAndHisotryForDevice(_ device: CHSesame2) {
        if let storeDevice = getSesame2Property(device) {
            propertyObjectContext.delete(storeDevice)
        }
        saveIfNeeded()
    }
    
    func getOrCreatePropertyOfSesame2(_ sesame2: CHSesame2) -> Sesame2PropertyMO {
        if let property = getSesame2Property(sesame2) {
            return property
        } else {
            return createSesame2Property(sesame2)
        }
    }
    
    func getSesame2Property(_ device: CHSesame2) -> Sesame2PropertyMO? {
        let request: NSFetchRequest<Sesame2PropertyMO> = Sesame2PropertyMO.fetchRequest()
        request.predicate = NSPredicate(format: "deviceID == %@", device.deviceId as CVarArg)
        let devices = try? propertyObjectContext.fetch(request)
        if let foundDevice = devices?.first {
            return foundDevice
        } else {
            return nil
        }
    }
    
    @discardableResult
    private func createSesame2Property(_ device: CHSesame2) -> Sesame2PropertyMO {
        let property = Sesame2PropertyMO(context: propertyObjectContext)
        property.deviceID = device.deviceId
        propertyObjectContext.insert(property)
        saveIfNeeded()
        
        return property
    }
}

enum AutoUnlockType: Int {
    case off = 0
    case gps
    case backgroundBle
}

extension Sesame2Store {
    func saveAutoUnlockForSesame2(_ sesame2: CHSesame2, type: AutoUnlockType) {
        savePropertyToDevice(sesame2, withProperties: ["autoUnlockType" : type.rawValue])
    }
    
    func saveSiriShortcutForSesame2(_ sesame2: CHSesame2, enable: Bool) {
        savePropertyToDevice(sesame2, withProperties: ["siriShortcutUnlock" : enable])
    }
    
    func saveLocationForSesame2(_ sesame2: CHSesame2, location: CLLocation) {
        
        savePropertyToDevice(sesame2, withProperties: ["latitude" : location.coordinate.latitude])
        savePropertyToDevice(sesame2, withProperties: ["longitude" : location.coordinate.longitude])
    }
}
