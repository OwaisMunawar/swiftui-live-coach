import AppIntents
import CoachCore
import SwiftData

struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static let defaultQuery = HabitEntityQuery()

    let id: UUID
    let name: String
    let symbolName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: symbolName))
    }

    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        symbolName = habit.symbolName
    }
}

struct HabitEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let wanted = Set(identifiers)
        return try SharedModelContainer.shared.mainContext.habits()
            .filter { wanted.contains($0.id) }
            .map(HabitEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [HabitEntity] {
        try SharedModelContainer.shared.mainContext.habits()
            .filter { $0.name.localizedStandardContains(string) }
            .map(HabitEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        try SharedModelContainer.shared.mainContext.habits().map(HabitEntity.init)
    }
}
