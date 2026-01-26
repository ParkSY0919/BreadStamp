import Foundation
import SwiftData

@Model
final class Bread {
    var id: UUID
    var name: String
    var category: BreadCategory
    @Attribute(.externalStorage)
    var imageData: Data?
    var rating: Int
    var memo: String?
    var eatenAt: Date

    var bakery: Bakery?

    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        category: BreadCategory,
        imageData: Data? = nil,
        rating: Int = 3,
        memo: String? = nil,
        bakery: Bakery? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.imageData = imageData
        self.rating = min(max(rating, 1), 5)
        self.memo = memo
        self.eatenAt = Date()
        self.bakery = bakery
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
