import Foundation
import SwiftData

@Model
final class Brewer {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String?
    var style: String?
    var notes: String?
    var isFavorite: Bool = false
    @Attribute(.externalStorage) var photoData: Data?
    var photoPath: String?
    
    @Relationship(inverse: \BrewEntry.brewer) var brews: [BrewEntry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        style: String? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        photoData: Data? = nil,
        photoPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.style = style
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.photoPath = photoPath
    }
}


