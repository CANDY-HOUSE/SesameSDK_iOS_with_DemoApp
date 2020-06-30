//
//  SSMStore.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/25.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreData
import SesameSDK

public protocol Storable {
    associatedtype T
    func valueForKey(_ key: String) -> T?
    func setValue(_ value: T, forKey key: String) -> Bool
    func removeValueForKey(_ key: String)
}

public final class AnyObjectStore<T: Codable>: Storable {
    public func valueForKey(_ key: String) -> T? {
        guard let data = UserDefaults.standard.value(forKey: key) as? Data,
        let decoded = try? PropertyListDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    @discardableResult
    public func setValue(_ value: T, forKey key: String) -> Bool {
        guard let encoded = try? PropertyListEncoder().encode(value) else {
            return false
        }
        UserDefaults.standard.setValue(encoded, forKey: key)
        return true
    }
    
    public func removeValueForKey(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

class SSMStore: NSObject, NSFetchedResultsControllerDelegate {
    static let shared = SSMStore {
        
    }
    
    private var cache = NSCache<NSString, SSMProperty>()
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
    
    func savePropertyForDevice(_ device: CHSesameBleInterface, withName name: String) {
        
        var ssmStore: SSMProperty!
        if let ssm = getDevicePropertyFromDBForDevice(device) {
            ssm.setValue(name, forKey: "name")
            ssmStore = ssm
        } else {
            let ssm = SSMProperty(context: managedObjectContext)
            ssm.uuid = device.deviceId
            ssm.name = name
            ssmStore = ssm
        }

        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch  {
                L.d("save error",error)
            }
            cache.setObject(ssmStore, forKey: ssmStore.uuid!.uuidString as NSString)
        }
    }
    
    func deletePropertyForDevice(_ device: CHSesameBleInterface) {
        guard let storeDevice = getPropertyForDevice(device) else {
            return
        }
        managedObjectContext.delete(storeDevice)
        cache.removeObject(forKey: device.deviceId.uuidString as NSString)
    }
    
    func getPropertyForDevice(_ device: CHSesameBleInterface) -> SSMProperty? {
        
        guard let cachedDevice = cache.object(forKey: device.deviceId.uuidString as NSString) else {
            return getDevicePropertyFromDBForDevice(device)
        }
        return cachedDevice
    }
    
    func getDevicePropertyFromDBForDevice(_ device: CHSesameBleInterface) -> SSMProperty? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SSM")
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", device.deviceId.uuidString as CVarArg)
        
        let request: NSFetchRequest<SSMProperty> = SSMProperty.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", device.deviceId.uuidString as CVarArg)
        let devices = (try? managedObjectContext.fetch(request)) ?? [SSMProperty]()
        if let foundDevice = devices.first {
            return foundDevice
        } else {
            return nil
        }
    }
}

public struct SSMWrapper: Codable {
    let uuid: UUID
    let ssmName: String?
}
