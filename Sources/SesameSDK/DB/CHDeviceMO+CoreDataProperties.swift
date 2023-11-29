//
//  CHDeviceMO+CoreDataProperties.swift
//  SesameSDK
//
//  Created by eddy on 2023/11/24.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
//

import Foundation
import CoreData


extension CHDeviceMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CHDeviceMO> {
        return NSFetchRequest<CHDeviceMO>(entityName: "CHDevice")
    }

    @NSManaged public var deviceModel: String?
    @NSManaged public var deviceUUID: String?
    @NSManaged public var historyTag: Data?
    @NSManaged public var keyIndex: String?
    @NSManaged public var secretKey: String?
    @NSManaged public var sesame2PublicKey: String?

}

extension CHDeviceMO : Identifiable {

}
