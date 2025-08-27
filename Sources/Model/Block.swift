import Foundation
import CoreData

@objc(Block)
public class Block: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var noteId: UUID
    @NSManaged public var type: String
    @NSManaged public var text: String?
    @NSManaged public var order: Int16
    @NSManaged public var style: Data?
    @NSManaged public var note: Note?
    @NSManaged public var strokes: NSSet?
}

extension Block {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Block> {
        return NSFetchRequest<Block>(entityName: "Block")
    }
}
