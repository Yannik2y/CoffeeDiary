import Foundation
import SwiftData

@Model
final class Machine {
    // CloudKit: avoid unique constraints and provide defaults
    var id: UUID = UUID()
    var name: String = ""
    var brand: String?
    var model: String?
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?
    var photoPath: String?
    var isActive: Bool = false
    var brandId: String?
    
    // Inverse relationship for CloudKit (must be optional)
    @Relationship(inverse: \BrewEntry.machine) var brews: [BrewEntry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        model: String? = nil,
        notes: String? = nil,
        photoData: Data? = nil,
        photoPath: String? = nil,
        isActive: Bool = false,
        brandId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.notes = notes
        self.photoData = photoData
        self.photoPath = photoPath
        self.isActive = isActive
        self.brandId = brandId
    }
}

