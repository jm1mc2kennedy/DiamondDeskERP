//
//  Customers+CoreDataProperties.swift
//  TRex
//
//  Created by Pawan K Sharma on 09/02/23.
//
//

import Foundation
import CoreData

extension Customers {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customers> {
        return NSFetchRequest<Customers>(entityName: "Customers")
    }

    @NSManaged public var businessName: String?
    @NSManaged public var customerID: String?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var password: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var status: String?
    @NSManaged public var `operator`: String?
}

extension Customers : Identifiable {

}
