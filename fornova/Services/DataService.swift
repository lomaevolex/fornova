import Foundation
import CoreData

final class DataService {
    static let shared = DataService()
    let context: NSManagedObjectContext

    private init() {
        context = PersistenceController.shared.container.viewContext
    }

    func fetchDocuments() throws -> [DocumentEntity] {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DocumentEntity.creationDate, ascending: false)]
        return try context.fetch(request)
    }

    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func delete(_ doc: DocumentEntity) throws {
        context.delete(doc)
        try saveContext()
    }
}
