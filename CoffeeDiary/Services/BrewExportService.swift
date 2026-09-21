import Foundation

struct BrewExportService {
    private static let iso8601 = ISO8601DateFormatter()

    enum ExportError: Error {
        case serializationFailed
        case writeFailed
    }

    static func exportJSON(brews: [BrewEntry]) -> Data? {
        let records: [[String: Any]] = brews.map { entry in
            [
                "id": entry.id.uuidString,
                "createdAt": iso8601.string(from: entry.createdAt),
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
        for entry in brews {
            let fields = [
                iso8601.string(from: entry.createdAt),
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

    /// Writes export data to a unique temp file. Caller may delete after sharing.
    static func writeTemporaryFile(data: Data, preferredName: String) throws -> URL {
        let unique = "\(UUID().uuidString)-\(preferredName)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(unique)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw ExportError.writeFailed
        }
    }

    static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
