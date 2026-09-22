import Foundation

enum EquipmentCategory: String, Codable, CaseIterable {
    case machine
    case grinder
}

/// Generic build-type illustration shown when no user photo exists.
/// Raw values are stored on Machine/Grinder and referenced from the model catalog,
/// so they must stay stable.
enum EquipmentSilhouette: String, Codable, CaseIterable, Identifiable {
    case machineE61 = "machine_e61"
    case machineCompact = "machine_compact"
    case machineCommercial = "machine_commercial"
    case machineLever = "machine_lever"
    case machineHome = "machine_home"

    case grinderHopper = "grinder_hopper"
    case grinderSingleDose = "grinder_single_dose"
    case grinderHand = "grinder_hand"
    case grinderCommercial = "grinder_commercial"

    var id: String { rawValue }

    var category: EquipmentCategory {
        switch self {
        case .machineE61, .machineCompact, .machineCommercial, .machineLever, .machineHome:
            return .machine
        case .grinderHopper, .grinderSingleDose, .grinderHand, .grinderCommercial:
            return .grinder
        }
    }

    var title: String {
        switch self {
        case .machineE61: return "E61 / Dual Boiler".localized
        case .machineCompact: return "Compact".localized
        case .machineCommercial: return "Commercial".localized
        case .machineLever: return "Lever".localized
        case .machineHome: return "Built-in Grinder".localized
        case .grinderHopper: return "Hopper Grinder".localized
        case .grinderSingleDose: return "Single Dose".localized
        case .grinderHand: return "Hand Grinder".localized
        case .grinderCommercial: return "Shop Grinder".localized
        }
    }

    static func all(for category: EquipmentCategory) -> [EquipmentSilhouette] {
        allCases.filter { $0.category == category }
    }

    static func defaultSilhouette(for category: EquipmentCategory) -> EquipmentSilhouette {
        switch category {
        case .machine: return .machineCompact
        case .grinder: return .grinderHopper
        }
    }

    /// An explicit choice wins, then the catalog model, then a neutral silhouette per category.
    static func resolve(silhouetteId: String?, modelId: String?, category: EquipmentCategory) -> EquipmentSilhouette {
        if let silhouetteId,
           let manual = EquipmentSilhouette(rawValue: silhouetteId),
           manual.category == category {
            return manual
        }
        if let modelId,
           let model = EquipmentCatalog.model(id: modelId),
           model.category == category {
            return model.silhouette
        }
        return defaultSilhouette(for: category)
    }
}

extension Machine {
    var silhouette: EquipmentSilhouette {
        EquipmentSilhouette.resolve(silhouetteId: silhouetteId, modelId: modelId, category: .machine)
    }
}

extension Grinder {
    var silhouette: EquipmentSilhouette {
        EquipmentSilhouette.resolve(silhouetteId: silhouetteId, modelId: modelId, category: .grinder)
    }
}
