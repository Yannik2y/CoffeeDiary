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

    @discardableResult
    func save(_ context: ModelContext, errorMessage: String? = nil) -> Bool {
        let resolvedMessage = errorMessage ?? "Failed to save".localized
        do {
            try context.save()
            lastSaveError = nil
            return true
        } catch {
            lastSaveError = resolvedMessage
            NotificationCenter.default.post(
                name: .modelContextSaveError,
                object: nil,
                userInfo: ["message": resolvedMessage]
            )
            return false
        }
    }

    func saveAsync(_ context: ModelContext, errorMessage: String? = nil) async -> Bool {
        save(context, errorMessage: errorMessage)
    }

    func duplicate(_ entry: BrewEntry, in context: ModelContext) -> BrewEntry {
        let copy = BrewEntry.duplicate(from: entry)
        context.insert(copy)
        return copy
    }

    func referencedBrewCount(for item: EquipmentItem, in context: ModelContext) -> Int {
        let descriptor: FetchDescriptor<BrewEntry>
        switch item {
        case .bean(let b):
            let id = b.id
            descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.bean?.id == id })
        case .grinder(let g):
            let id = g.id
            descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.grinder?.id == id })
        case .machine(let m):
            let id = m.id
            descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.machine?.id == id })
        case .brewer(let br):
            let id = br.id
            descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.brewer?.id == id })
        }
        return (try? context.fetchCount(descriptor)) ?? 0
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
            let descriptor: FetchDescriptor<BrewEntry>
            switch item {
            case .bean(let b):
                let id = b.id
                descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.bean?.id == id })
            case .grinder(let g):
                let id = g.id
                descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.grinder?.id == id })
            case .machine(let m):
                let id = m.id
                descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.machine?.id == id })
            case .brewer(let br):
                let id = br.id
                descriptor = FetchDescriptor<BrewEntry>(predicate: #Predicate { $0.brewer?.id == id })
            }
            if let brews = try? context.fetch(descriptor) {
                for brew in brews {
                    switch item {
                    case .bean: brew.bean = nil
                    case .grinder: brew.grinder = nil
                    case .machine: brew.machine = nil
                    case .brewer: brew.brewer = nil
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
        return save(context)
    }

    /// Enforces a single active machine. Pass `makeActive: false` to deactivate without selecting another.
    func setActiveMachine(_ machine: Machine, allMachines: [Machine], makeActive: Bool = true) {
        if makeActive {
            for m in allMachines { m.isActive = m.id == machine.id }
        } else {
            machine.isActive = false
        }
    }

    func setActiveGrinder(_ grinder: Grinder, allGrinders: [Grinder], makeActive: Bool = true) {
        if makeActive {
            for g in allGrinders { g.isActive = g.id == grinder.id }
        } else {
            grinder.isActive = false
        }
    }

    /// After create or edit: if the item should be active, clear others; if toggled off and it was the only one, leave zero actives.
    func applyActiveMachineSelection(_ machine: Machine, isActive: Bool, allMachines: [Machine]) {
        if isActive {
            setActiveMachine(machine, allMachines: allMachines, makeActive: true)
        } else {
            machine.isActive = false
        }
    }

    func applyActiveGrinderSelection(_ grinder: Grinder, isActive: Bool, allGrinders: [Grinder]) {
        if isActive {
            setActiveGrinder(grinder, allGrinders: allGrinders, makeActive: true)
        } else {
            grinder.isActive = false
        }
    }

    /// Ensures at most one active machine and one active grinder (e.g. after CloudKit merge).
    func reconcileActiveEquipment(machines: [Machine], grinders: [Grinder]) {
        let activeMachines = machines.filter(\.isActive)
        if activeMachines.count > 1, let keep = activeMachines.first {
            setActiveMachine(keep, allMachines: machines, makeActive: true)
        }
        let activeGrinders = grinders.filter(\.isActive)
        if activeGrinders.count > 1, let keep = activeGrinders.first {
            setActiveGrinder(keep, allGrinders: grinders, makeActive: true)
        }
    }
}

extension Notification.Name {
    static let modelContextSaveError = Notification.Name("ModelContextSaveError")
}
