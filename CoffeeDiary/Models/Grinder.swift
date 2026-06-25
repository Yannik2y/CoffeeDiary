import Foundation
import SwiftData

@Model
final class Grinder {
    // CloudKit: avoid unique constraints and provide defaults
    var id: UUID = UUID()
    var name: String = ""
    var brand: String?
    var burrType: String?
    var notes: String?
    var defaultSetting: Double?
    @Attribute(.externalStorage) var photoData: Data?
    var photoPath: String?
    var isActive: Bool = false
    var brandId: String?
    
    // Inverse relationship for CloudKit (must be optional)
    @Relationship(inverse: \BrewEntry.grinder) var brews: [BrewEntry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        burrType: String? = nil,
        notes: String? = nil,
        defaultSetting: Double? = nil,
        photoData: Data? = nil,
        photoPath: String? = nil,
        isActive: Bool = false,
        brandId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.burrType = burrType
        self.notes = notes
        self.defaultSetting = defaultSetting
        self.photoData = photoData
        self.photoPath = photoPath
        self.isActive = isActive
        self.brandId = brandId
    }
}

