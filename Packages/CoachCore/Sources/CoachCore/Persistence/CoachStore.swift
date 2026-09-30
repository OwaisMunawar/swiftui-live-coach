import Foundation
import SwiftData

/// Builds the SwiftData container shared by the app, the widget extension and
/// App Intents. The store lives in the App Group container so all three
/// processes read and write the same file. Ownership of the live container is
/// left to the composition root in each target; this type holds no state.
public enum CoachStore {
    public static let appGroupID = "group.com.owaismunawar.livecoach"

    public static var schema: Schema {
        Schema([Habit.self, HabitCompletion.self, WorkoutSession.self])
    }

    public static func makeContainer(inMemory: Bool = false, appGroupID: String = appGroupID) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration(schema: schema, url: try storeURL(appGroupID: appGroupID))
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func storeURL(appGroupID: String) throws -> URL {
        let fileManager = FileManager.default
        let base = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? URL.applicationSupportDirectory
        let directory = base.appending(path: "LiveCoach", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "Coach.store")
    }
}

extension ModelContext {
    public func habits() throws -> [Habit] {
        try fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
    }

    public func habit(id: UUID) throws -> Habit? {
        var descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    public func workoutSession(id: UUID) throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    public func activeWorkoutSession() throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    public func workoutSessions(since date: Date) throws -> [WorkoutSession] {
        try fetch(FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.startedAt >= date },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))
    }
}
