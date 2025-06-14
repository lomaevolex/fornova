//
//  DocumentEntity+CoreDataProperties.swift
//  fornova
//
//  Created by lomaev on 13/6/25.
//
//

import Foundation
import CoreData


extension DocumentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocumentEntity> {
        return NSFetchRequest<DocumentEntity>(entityName: "DocumentEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var url: String?

}

extension DocumentEntity : Identifiable {

}
