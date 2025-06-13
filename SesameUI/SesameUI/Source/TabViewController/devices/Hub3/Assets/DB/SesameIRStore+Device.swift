//
//  SesameIRStore+Device.swift
//  SesameUI
//
//  Created by eddy on 2024/6/28.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import CoreData

extension SesIRDevice {
//    @NSManaged public var device_name: String?
//    @NSManaged public var device_res: Int16
//    @NSManaged public var device_type: Int32
//    @NSManaged public var gid: Int16
//    @NSManaged public var id: Int16
    func updateIRDevice(_ device: ETDevice) {
        id = Int16(device.mID!)
        gid = device.mGID!
        device_type = Int64(device.mType!)
        device_res = Int16(device.mResId!)
        device_name = device.mName!
    }
}

extension SesameIRStore {
    
    func fetchLatestDeviceId(callback: @escaping (Int16?) -> Void) {
        let deviceRequest: NSFetchRequest<SesIRDevice> = SesIRDevice.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        deviceRequest.sortDescriptors = [sortDescriptor]
        deviceRequest.fetchLimit = 1
        backgroundContext.perform { [self] in
            do {
                let res = try self.backgroundContext.fetch(deviceRequest).first
                callback(res?.id)
            } catch let error as NSError {
                L.d("Fetch error: \(error), \(error.userInfo)")
                callback(nil)
            }
        }
    }

    
    func fetchDevicesByGroupId(_ mid: String, callback: @escaping ([SesIRDevice]?) -> Void){
        let deviceRequest: NSFetchRequest<SesIRDevice> = SesIRDevice.fetchRequest()
        deviceRequest.predicate = NSPredicate(format: "gid == %@", mid)
        backgroundContext.perform { [self] in
            do {
                let res = try self.backgroundContext.fetch(deviceRequest)
                callback(res)
            } catch let error as NSError {
                L.d("Fetch error: \(error), \(error.userInfo)")
                callback(nil)
            }
        }
    }
    
    func deleteDevicesById(_ id: Int, callback: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<SesIRDevice> = SesIRDevice.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        backgroundContext.perform { [self] in
            do {
                let devices = try self.backgroundContext.fetch(fetchRequest)
                if let deviceToDelete = devices.first {
                    self.backgroundContext.delete(deviceToDelete)
                    if backgroundContext.hasChanges {
                        try self.backgroundContext.save()
                    }
                    callback(true)
                } else {
                    callback(true)
                }
            } catch {
                callback(false)
                print("Failed to fetch or delete device: \(error)")
            }
        }
    }
    
    
}
