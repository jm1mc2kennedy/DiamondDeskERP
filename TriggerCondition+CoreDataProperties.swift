//  OperatorEntity+CoreDataProperties.swift
//  MyApp
//
//  Created by Developer on 2023-05-01.
//
//

import Foundation
import CoreData

extension OperatorEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OperatorEntity> {
        return NSFetchRequest<OperatorEntity>(entityName: "OperatorEntity")
    }

    @NSManaged public var id: UUID?
    // 'operator' is a reserved keyword in Swift; using 'op' instead.
    @NSManaged public var op: String?
    @NSManaged public var name: String?
}
