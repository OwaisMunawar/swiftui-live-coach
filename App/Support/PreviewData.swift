import CoachCore
import SwiftData

@MainActor
enum PreviewData {
    /// In-memory container pre-filled with the demo dataset, for `#Preview`.
    static let container: ModelContainer = {
        do {
            let container = try CoachStore.makeContainer(inMemory: true)
            try DemoSeed.populate(container.mainContext)
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }()
}
