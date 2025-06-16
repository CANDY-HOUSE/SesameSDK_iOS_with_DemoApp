//
//  IRDeviceSerivce.swift
//  SesameUI
//
//  Created by eddy on 2024/7/18.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import CoreData


protocol CoreDataChangeDelegate: AnyObject {
    func persistentDataDidChange()
}

class IRDeviceService: NSObject {
    
    public private(set) var multicastDelegate = CHMulticastDelegate<CoreDataChangeDelegate>()
    public private(set) var irGroups = [ETGroup]()

    override init() {
        super.init()
        monitorDataChanges()
    }
    
    private func monitorDataChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange(_:)),
            name: .NSManagedObjectContextObjectsDidChange,
            object: ETDB.instance.backgroundContext
        )
    }
    
    func deviceById(_ id: String) -> ETGroup? {
        guard !id.isEmpty else {
            return nil
        }
        return irGroups.first(where: { $0.mID == id })
    }
    
    func handleDevices(_ devices: [CHDevice]) {
        irGroups.removeAll()
        for device in devices {
            let hub3 = ETGroup()
            hub3.mID = device.deviceId.uuidString
            hub3.load(db: SesameIRStore.instance) {
            }
            irGroups.append(hub3)
        }
    }
    
    private func reloadGroupedDevices() {
        let dispatchGroup = DispatchGroup()
        for group in irGroups {
            dispatchGroup.enter()
            group.load(db: SesameIRStore.instance) {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.notifyDataChanged()
        }
    }
    
    @objc func contextDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
            }
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
            }
            reloadGroupedDevices()
        }
    }
    
    private func notifyDataChanged() {
        multicastDelegate.invokeDelegates { invokation in
            invokation.persistentDataDidChange()
        }
    }
}
