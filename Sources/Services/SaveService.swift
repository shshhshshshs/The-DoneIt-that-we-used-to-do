import Foundation
import CoreData
import PencilKit

final class SaveService {
    private let context: NSManagedObjectContext
    private let searchIndex: SearchIndex

    init(context: NSManagedObjectContext, searchIndex: SearchIndex) {
        self.context = context
        self.searchIndex = searchIndex
    }

    func save(note: Note, drawing: PKDrawing) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent("\(note.id.uuidString).drawing")
        do {
            try drawing.dataRepresentation().write(to: fileURL)
        } catch {
            print("Failed to save drawing: \(error)")
        }

        note.updatedAt = Date()
        let id = Int64(bitPattern: UInt64(note.id.uuidString.hashValue))
        let title = note.title
        let text = note.blockTexts()
        let keywords = note.keywords?.joined(separator: " ") ?? ""
        do {
            try context.save()
            DispatchQueue.global().async {
                self.searchIndex.upsert(id: id, title: title, text: text, keywords: keywords)
            }
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
}
