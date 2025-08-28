import Foundation
import CoreData

@objc(StringArrayTransformer)
final class StringArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [String] else { return nil }
        do {
            return try JSONEncoder().encode(array)
        } catch {
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            return nil
        }
    }
}
