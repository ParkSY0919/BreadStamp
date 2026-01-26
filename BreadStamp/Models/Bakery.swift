import Foundation
import SwiftData

@Model
final class Bakery {
    var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var visitedAt: Date
    var memo: String?
    var imageData: Data?
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade, inverse: \Bread.bakery)
    var breads: [Bread] = []

    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        address: String,
        latitude: Double = 0,
        longitude: Double = 0,
        memo: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.visitedAt = Date()
        self.memo = memo
        self.imageData = imageData
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var breadCount: Int {
        breads.count
    }

    var averageRating: Double {
        guard !breads.isEmpty else { return 0 }
        let total = breads.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(breads.count)
    }
}
