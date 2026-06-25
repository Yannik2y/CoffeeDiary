import Foundation
import SwiftData

@Model
final class Bean {
    // CloudKit: avoid unique constraints and provide defaults
    var id: UUID = UUID()
    var name: String = ""
    var roaster: String?
    var origin: String?
    var process: String?
    var variety: String?
    var arabicaPercentage: Double = 100
    var robustaPercentage: Double = 0
    var roastDate: Date?
    var notes: String?
    var isFavorite: Bool = false
    var isArchived: Bool = false
    @Attribute(.externalStorage) var photoData: Data?
    var photoPath: String?
    
    // Inverse relationship for CloudKit (must be optional)
    @Relationship(inverse: \BrewEntry.bean) var brews: [BrewEntry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        roaster: String? = nil,
        origin: String? = nil,
        process: String? = nil,
        variety: String? = nil,
        roastDate: Date? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        photoData: Data? = nil,
        photoPath: String? = nil,
        arabicaPercentage: Double = 100,
        robustaPercentage: Double = 0
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.origin = origin
        self.process = process
        self.variety = variety
        self.roastDate = roastDate
        self.notes = notes
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.photoData = photoData
        self.photoPath = photoPath
        self.arabicaPercentage = min(max(arabicaPercentage, 0), 100)
        self.robustaPercentage = min(max(robustaPercentage, 0), 100)
    }
}

