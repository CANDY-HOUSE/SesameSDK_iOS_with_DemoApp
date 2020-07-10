//
//  SSMHistoryMO+CoreDataProperties.swift
//
//
//  Created by YuHan Hsiao on 2020/7/6.
//
//

import Foundation
import CoreData


extension SSMHistoryMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SSMHistoryMO> {
        return NSFetchRequest<SSMHistoryMO>(entityName: "SSMHistory")
    }

    @NSManaged public var deviceID: UUID?
    @NSManaged public var historyTag: Data?
    @NSManaged public var historyType: Int64
    @NSManaged public var timeStamp: Int64
    @NSManaged public var enableCount: Int64
    @NSManaged public var sectionIdentifier: String?
    @NSManaged public var ssmProperty: SSMPropertyMO?

}
