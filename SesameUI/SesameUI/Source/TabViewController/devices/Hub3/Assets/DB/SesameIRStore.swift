//
//  SesameIRStore.swift
//  SesameUI
//
//  Created by eddy on 2024/6/6.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import CoreData
import SesameSDK

private let SesDBPathName = "SesameIRStore"
class SesameIRStore {
    
    static let instance = SesameIRStore()
    
    private var persistentContainer: NSPersistentContainer!
    public private(set) var backgroundContext: NSManagedObjectContext!
    
    init() {
        let modelURL = Bundle.main.path(forResource: SesDBPathName, ofType: "momd")
        let model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelURL!))
        let persistentContainer = NSPersistentContainer(name: NSStringFromClass(SesameIRStore.self), managedObjectModel: model!)
        if let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.candyhouse.widget") {
            let storeURL = fileContainer.appendingPathComponent("\(SesDBPathName).sqlite")
            L.d("storeURL is \(storeURL)")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.setOption(FileProtectionType.none as NSObject, forKey: NSPersistentStoreFileProtectionKey)
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        persistentContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                L.d(error)
            }
        })
        self.persistentContainer = persistentContainer
        self.backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    // MARK: General Save Method
    func saveChanges(completion: @escaping (Bool, Error?) -> Void) {
        backgroundContext.perform {
            do {
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                }
                L.d("保存成功")
                completion(true, nil)
            } catch let error {
                L.d("Error saving context: \(error)")
                completion(false, error)
            }
        }
    }
}
