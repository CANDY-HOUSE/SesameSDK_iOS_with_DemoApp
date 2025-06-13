//
//  SesameIRStore+Air.swift
//  SesameUI
//
//  Created by eddy on 2024/7/8.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import CoreData

extension SesAirDevice {
//    @NSManaged public var air_auto_dir: Int16
//    @NSManaged public var air_cool: Int16
//    @NSManaged public var air_dir: Int16
//    @NSManaged public var air_eco: Int16
//    @NSManaged public var air_heat: Int16
//    @NSManaged public var air_hot: Int16
//    @NSManaged public var air_light: Int16
//    @NSManaged public var air_mode: Int16
//    @NSManaged public var air_mute: Int16
//    @NSManaged public var air_power: Int16
//    @NSManaged public var air_rate: Int16
//    @NSManaged public var air_sleep: Int16
//    @NSManaged public var air_string: Int16
//    @NSManaged public var air_temp: Int16
//    @NSManaged public var air_xx: Int16
//    @NSManaged public var did: Int16
//    @NSManaged public var id: Int16
    func updateAirDevice(_ key: ETDeviceAir) {
        id = Int16(key.mID!)
        did = Int16(key.mID!)
        air_temp = Int16(key.air.mTemperature)
        air_rate = Int16(key.air.mWindRate)
        air_dir = Int16(key.air.mWindDirection)
        air_auto_dir = Int16(key.air.mAutomaticWindDirection)
        air_mode = Int16(key.air.mMode)
        air_power = Int16(key.air.mPower)
        air_sleep = Int16(key.air.mSleep)
        air_light = Int16(key.air.mLight)
        air_heat = Int16(key.air.mHeat)
        air_eco = Int16(key.air.mEco)
//        air_cool = key.air_cool
//        air_hot = key.air_hot
//        air_mute = key.air_mute
//        air_string = key.air_string
//        air_xx = key.air_xx
    }
}

extension SesameIRStore {
    
    func insertDevice(_ device: ETDevice, keys: [ETKey], completion: @escaping (Bool) -> Void) {
        backgroundContext.perform { [self] in
            let newDevice = SesIRDevice(context: self.backgroundContext)
            newDevice.updateIRDevice(device)
            
            if let airD = device as? ETDeviceAir {
                let newAirDevice = SesAirDevice(context: self.backgroundContext)
                newAirDevice.updateAirDevice(airD)
                newDevice.air = newAirDevice
            }

            var addKeys = [SesIRKey]()
            for key in keys {
                let etKey = SesIRKey(context: self.backgroundContext)
                etKey.updateIRKey(key)
                etKey.did = newDevice.id
                addKeys.append(etKey)
            }
            if !addKeys.isEmpty {            
                newDevice.keys = NSSet(array: addKeys)
            }
            do {
                if backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                }
                completion(true)
            } catch {
                L.d("Error saving ETDevice: \(error)")
                completion(false)
            }
        }
    }
    
    func fetchAirByDeviceId(_ id: Int, callback: @escaping (SesAirDevice?) -> Void) {
        let deviceRequest: NSFetchRequest<SesAirDevice> = SesAirDevice.fetchRequest()
        deviceRequest.predicate = NSPredicate(format: "did == %d", id)
        backgroundContext.perform { [self] in
            do {
                let res = try self.backgroundContext.fetch(deviceRequest).first
                callback(res)
            } catch let error as NSError {
                L.d("Fetch error: \(error), \(error.userInfo)")
                callback(nil)
            }
        }
    }
}
