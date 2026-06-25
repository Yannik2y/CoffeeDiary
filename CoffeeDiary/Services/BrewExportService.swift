import Foundation

struct BrewExportService {
    static func exportJSON(brews: [BrewEntry]) -> Data? {
        let records: [[String: Any]] = brews.map { entry in
            [
                "id": entry.id.uuidString,
                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt),
                "coffeeName": entry.coffeeName,
                "brewStyle": entry.brewStyleRaw,
                "shotType": entry.shotType.rawValue,
                "doseGrams": entry.doseGrams,
                "yieldGrams": entry.yieldGrams,
                "brewTimeSeconds": entry.brewTimeSeconds,
                "grinderSetting": entry.grinderSetting,
                "rating": entry.rating,
                "notes": entry.notes ?? "",
                "bean": entry.bean?.name ?? "",
                "grinder": entry.grinder?.name ?? "",
                "machine": entry.machine?.name ?? "",
                "brewer": entry.brewer?.name ?? ""
            ]
        }
        return try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
    }

    static func exportCSV(brews: [BrewEntry]) -> String {
        var lines = ["date,coffee,style,shot,dose,yield,time,grinder_setting,rating,bean,notes"]
        let formatter = ISO8601DateFormatter()
        for entry in brews {
            let fields = [
                formatter.string(from: entry.createdAt),
                csvEscape(entry.coffeeName),
                entry.brewStyleRaw,
                "\(entry.shotType.rawValue)",
                "\(entry.doseGrams)",
                "\(entry.yieldGrams)",
                "\(entry.brewTimeSeconds)",
                "\(entry.grinderSetting)",
                "\(entry.rating)",
                csvEscape(entry.bean?.name ?? ""),
                csvEscape(entry.notes ?? "")
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
