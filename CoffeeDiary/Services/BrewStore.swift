import Foundation
import SwiftData
import Observation

enum EquipmentDeletePolicy {
    case nullifyRelationships
    case blockIfReferenced
}

@Observable
@MainActor
final class BrewStore {
    static let shared = BrewStore()

    var lastSaveError: String?

    private init() {}

    func save(_ context: ModelContext, errorMessage: String? = nil) {
        let resolvedMessage = errorMessage ?? "Failed to save".localized
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            lastSaveError = resolvedMessage
            NotificationCenter.default.post(
                name: .modelContextSaveError,
                object: nil,
                userInfo: ["message": resolvedMessage]
            )
        }
    }

    func saveAsync(_ context: ModelContext, errorMessage: String? = nil) async {
        save(context, errorMessage: errorMessage)
    }

    func duplicate(_ entry: BrewEntry, in context: ModelContext) -> BrewEntry {
        let copy = BrewEntry.duplicate(from: entry)
        context.insert(copy)
        return copy
    }

    func referencedBrewCount(for item: EquipmentItem, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<BrewEntry>()
        guard let brews = try? context.fetch(descriptor) else { return 0 }
        return brews.filter { brew in
            switch item {
            case .bean(let b): return brew.bean?.id == b.id
            case .grinder(let g): return brew.grinder?.id == g.id
            case .machine(let m): return brew.machine?.id == m.id
            case .brewer(let br): return brew.brewer?.id == br.id
            }
        }.count
    }

    func deleteEquipment(
        _ item: EquipmentItem,
        policy: EquipmentDeletePolicy,
        in context: ModelContext
    ) -> Bool {
        let count = referencedBrewCount(for: item, in: context)
        if count > 0 && policy == .blockIfReferenced {
            return false
        }
        if count > 0 {
            let descriptor = FetchDescriptor<BrewEntry>()
            if let brews = try? context.fetch(descriptor) {
                for brew in brews {
                    switch item {
                    case .bean(let b) where brew.bean?.id == b.id: brew.bean = nil
                    case .grinder(let g) where brew.grinder?.id == g.id: brew.grinder = nil
                    case .machine(let m) where brew.machine?.id == m.id: brew.machine = nil
                    case .brewer(let br) where brew.brewer?.id == br.id: brew.brewer = nil
                    default: break
                    }
                }
            }
        }
        switch item {
        case .bean(let b): context.delete(b)
        case .grinder(let g): context.delete(g)
        case .machine(let m): context.delete(m)
        case .brewer(let br): context.delete(br)
        }
        save(context)
        return true
    }

    func setActiveMachine(_ machine: Machine, allMachines: [Machine]) {
        for m in allMachines { m.isActive = m.id == machine.id }
    }

    func setActiveGrinder(_ grinder: Grinder, allGrinders: [Grinder]) {
        for g in allGrinders { g.isActive = g.id == grinder.id }
    }
}

extension Notification.Name {
    static let modelContextSaveError = Notification.Name("ModelContextSaveError")
}
