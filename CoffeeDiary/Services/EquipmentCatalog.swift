import Foundation

struct EquipmentModel: Codable, Identifiable, Hashable {
    enum BurrType: String, Codable {
        case flat
        case conical

        var title: String {
            switch self {
            case .flat: return "Flat burrs".localized
            case .conical: return "Conical burrs".localized
            }
        }
    }

    let id: String
    let brandId: String
    let name: String
    let category: EquipmentCategory
    let silhouette: EquipmentSilhouette
    var burrType: BurrType?
    var burrSizeMm: Int?

    var brand: CoffeeBrand? {
        BrandDatabase.brand(id: brandId)
    }

    var brandName: String {
        brand?.name ?? brandId
    }

    /// Localized description used to prefill a grinder's burr field, e.g. "Flat burrs 64 mm".
    var burrDescription: String? {
        guard let burrType else { return nil }
        if let burrSizeMm {
            return "\(burrType.title) \(burrSizeMm) mm"
        }
        return burrType.title
    }
}

/// Bundled catalog of known machines and grinders. Read-only reference data;
/// user entries keep their own free-text brand/model and only store the catalog ids.
enum EquipmentCatalog {
    static let models: [EquipmentModel] = loadModels()

    private static let modelsById: [String: EquipmentModel] = Dictionary(
        models.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func loadModels(bundle: Bundle = .main) -> [EquipmentModel] {
        guard let url = bundle.url(forResource: "equipment_models", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let models = try? JSONDecoder().decode([EquipmentModel].self, from: data) else {
            return []
        }
        return models
    }

    static func model(id: String) -> EquipmentModel? {
        modelsById[id]
    }

    static func models(for category: EquipmentCategory, brandId: String? = nil) -> [EquipmentModel] {
        models.filter { model in
            model.category == category && (brandId == nil || model.brandId == brandId)
        }
    }

    /// Brands that have at least one catalog model in the category, sorted by name.
    static func brands(for category: EquipmentCategory) -> [CoffeeBrand] {
        let ids = Set(models(for: category).map(\.brandId))
        return BrandDatabase.brands
            .filter { ids.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Matches on model name and brand name so "pro 700" and "profitec" both hit.
    static func search(_ query: String, category: EquipmentCategory, brandId: String? = nil) -> [EquipmentModel] {
        let candidates = models(for: category, brandId: brandId)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return candidates }
        return candidates.filter { model in
            model.name.localizedCaseInsensitiveContains(q)
                || model.brandName.localizedCaseInsensitiveContains(q)
                || "\(model.brandName) \(model.name)".localizedCaseInsensitiveContains(q)
        }
    }
}
