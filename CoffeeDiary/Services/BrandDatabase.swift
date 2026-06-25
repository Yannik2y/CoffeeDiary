import Foundation

struct CoffeeBrand: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let country: String?
}

enum BrandDatabase {
    static let brands: [CoffeeBrand] = loadBrands()

    static func loadBrands() -> [CoffeeBrand] {
        guard let url = Bundle.main.url(forResource: "brands", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let brands = try? JSONDecoder().decode([CoffeeBrand].self, from: data) else {
            return fallbackBrands
        }
        return brands
    }

    static func search(_ query: String) -> [CoffeeBrand] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return brands }
        return brands.filter {
            $0.name.lowercased().contains(q) || ($0.country?.lowercased().contains(q) ?? false)
        }
    }

    private static let fallbackBrands: [CoffeeBrand] = [
        CoffeeBrand(id: "la_marzocco", name: "La Marzocco", country: "Italy"),
        CoffeeBrand(id: "rocket", name: "Rocket Espresso", country: "Italy"),
        CoffeeBrand(id: "profitec", name: "Profitec", country: "Germany"),
        CoffeeBrand(id: "ecm", name: "ECM", country: "Germany"),
        CoffeeBrand(id: "lelit", name: "Lelit", country: "Italy"),
        CoffeeBrand(id: "breville", name: "Breville", country: "Australia"),
        CoffeeBrand(id: "gaggia", name: "Gaggia", country: "Italy"),
        CoffeeBrand(id: "rancilio", name: "Rancilio", country: "Italy"),
        CoffeeBrand(id: "nuova_simonelli", name: "Nuova Simonelli", country: "Italy"),
        CoffeeBrand(id: "mahlkonig", name: "Mahlkönig", country: "Germany"),
        CoffeeBrand(id: "mazzer", name: "Mazzer", country: "Italy"),
        CoffeeBrand(id: "baratza", name: "Baratza", country: "USA"),
        CoffeeBrand(id: "fellow", name: "Fellow", country: "USA"),
        CoffeeBrand(id: "comandante", name: "Comandante", country: "Germany"),
        CoffeeBrand(id: "eureka", name: "Eureka", country: "Italy"),
        CoffeeBrand(id: "df64", name: "DF64", country: "China"),
        CoffeeBrand(id: "acaia", name: "Acaia", country: "USA"),
        CoffeeBrand(id: "timemore", name: "Timemore", country: "China"),
        CoffeeBrand(id: "hario", name: "Hario", country: "Japan"),
        CoffeeBrand(id: "chemex", name: "Chemex", country: "USA")
    ]
}
