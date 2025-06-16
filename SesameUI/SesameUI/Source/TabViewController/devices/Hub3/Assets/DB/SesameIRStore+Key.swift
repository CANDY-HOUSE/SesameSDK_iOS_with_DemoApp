//
//  SesameIRStore+ETKey.swift
//  SesameUI
//
//  Created by eddy on 2024/6/18.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import CoreData


struct SesIRKeyModel {
    let gid: Int
    let name: String
    let res: Int
    let x: Float
    let y: Float
    let value: [Int8]
    let key: Int
    let brandIndex: Int
    let brandPos: Int
    let row: Int
    let state: Int
    
    init(gid: Int, name: String, res: Int, x: Float, y: Float, value: [Int8], key: Int, brandIndex: Int, brandPos: Int, row: Int, state: Int) {
        self.gid = gid
        self.name = name
        self.res = res
        self.x = x
        self.y = y
        self.value = value
        self.key = key
        self.brandIndex = brandIndex
        self.brandPos = brandPos
        self.row = row
        self.state = state
    }
    
//    func toDBModel() -> SesIRKey {
//        
//    }
}

extension SesIRKey {
//    @NSManaged public var did: Int16
//    @NSManaged public var id: Int16
//    @NSManaged public var key_brandindex: Int16
//    @NSManaged public var key_brandpos: Int16
//    @NSManaged public var key_key: Int32
//    @NSManaged public var key_name: String?
//    @NSManaged public var key_res: Int16
//    @NSManaged public var key_row: Int16
//    @NSManaged public var key_state: Int16
//    @NSManaged public var key_value: String?
//    @NSManaged public var key_x: Float
//    @NSManaged public var key_y: Float
    func updateIRKey(_ key: ETKey) {
        did = Int16(key.mDID)
        id = Int16(key.mID)
        key_brandindex = Int16(key.mBrandIndex)
        key_brandpos = Int16(key.mBrandPos)
        key_key = Int32(key.mKey)
        key_name = key.mName
        key_res = Int16(key.mResId)
        key_row = Int16(key.mRow)
        key_state = Int16(key.mState)
        key_value = key.mKeyValue.toHexString()
        key_x = key.mX
        key_y = key.mY
    }
}

extension SesameIRStore {
    
    func fetchETKeysByDeviceId(_ id: Int, callback: @escaping([SesIRKey]?) -> Void) {
        let deviceRequest: NSFetchRequest<SesIRKey> = SesIRKey.fetchRequest()
        deviceRequest.predicate = NSPredicate(format: "did == %d", id)
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
    
    func insertDeviceKey(_ key: ETKey, completion: @escaping (Bool) -> Void) {
        backgroundContext.perform { [self] in
            let newKey = SesIRKey(context: self.backgroundContext)
            newKey.did = Int16(key.mDID)
            newKey.id = Int16(key.mID)
            newKey.key_brandindex = Int16(key.mBrandIndex)
            newKey.key_brandpos = Int16(key.mBrandPos)
            newKey.key_key = Int32(key.mKey)
            newKey.key_name = key.mName
            newKey.key_res = Int16(key.mResId)
            newKey.key_row = Int16(key.mRow)
            newKey.key_state = Int16(key.mState)
            newKey.key_value = Data(key.mKeyValue.compactMap{ UInt8($0) }).toHexString()
            newKey.key_x = key.mX
            newKey.key_y = key.mY
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
}
