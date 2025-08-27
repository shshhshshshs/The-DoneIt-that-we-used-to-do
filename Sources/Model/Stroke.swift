import Foundation
import CoreData

@objc(Stroke)
public class Stroke: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var noteId: UUID
    @NSManaged public var blockId: UUID
    @NSManaged public var bbox: String
    @NSManaged public var archiveURL: URL?
    @NSManaged public var note: Note?
    @NSManaged public var block: Block?
}

extension Stroke {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Stroke> {
        return NSFetchRequest<Stroke>(entityName: "Stroke")
    }
}
