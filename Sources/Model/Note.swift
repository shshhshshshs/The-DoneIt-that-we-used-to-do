import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    /// Array of keywords persisted using `StringArrayTransformer`.
    @NSManaged public var keywords: [String]?
    @NSManaged public var blocks: NSSet?
}

extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    func blockTexts() -> String {
        let set = (blocks as? Set<Block>) ?? []
        let sorted = set.sorted { $0.order < $1.order }
        return sorted.compactMap { $0.text }.joined(separator: "\n")
    }
}
