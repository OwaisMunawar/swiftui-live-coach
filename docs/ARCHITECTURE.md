# Architecture

This document records the decisions behind LiveCoach's structure, in a short ADR style: the context, what was chosen, and what was considered and rejected.

## 1. Package boundaries

**Context.** The app has three processes touching the same data (app, widget extension, App Intents running in either) and several system frameworks that are awkward to test.

**Decision.** Four local Swift packages with a strict dependency direction, everything pointing at `CoachCore`:

| Package | Owns | Imports |
| --- | --- | --- |
| `CoachCore` | SwiftData models, `DayStamp`, streaks, `SessionClock`, `WeekSummary`, `PlanGenerating`, `RuleBasedPlanner`, demo seed, ActivityKit attributes | Foundation, SwiftData, ActivityKit (iOS only) |
| `CoachUI` | Reusable views: ring, check, stat tile, heatmap, timer text, activity chart | SwiftUI, Charts, CoachCore |
| `CoachIntelligence` | Foundation Models planner, availability mapping, fallback policy | FoundationModels, CoachCore |
| `CoachHealth` | `ActivityProviding` and the HealthKit implementation | HealthKit, CoachCore |

All packages declare `.macOS(.v26)` as well as iOS, so their tests run with `swift test` on a Mac without booting a simulator.

**Rejected.**
- *One package with many targets.* Works, but separate packages make the dependency graph visible in the file tree and stop a UI file from importing HealthKit by accident.
- *Everything in the app target.* Simplest, but nothing would be testable without a host app, and the widget extension would have to compile the whole app.

## 2. App Intents live in a shared source folder, not a package

**Context.** The interactive widget and Live Activity buttons reference intent types (`ToggleHabitIntent`, `TogglePauseWorkoutIntent`). Those types must exist in the widget extension, and the Live Activity intents must also exist in the app, because `LiveActivityIntent` runs in the app's process.

**Decision.** `Shared/` is a plain folder compiled into both targets. It holds the intents, `HabitEntity`, `WorkoutCoordinator` and the `SharedModelContainer` composition root.

**Rejected.** *Intents in a Swift package with `AppIntentsPackage`.* Supported, but metadata extraction across package boundaries is fragile across Xcode versions, and the app still needs its own `AppShortcutsProvider`. Sharing source files through target membership is simpler and has no such edge cases.

## 3. Dependency injection

**Context.** The brief for the domain layer is "no singletons": planners and health access must be swappable in tests and previews.

**Decision.** Protocol-based constructor injection.
- `PlanGenerating` (implemented by `RuleBasedPlanner` and `FoundationModelPlanner`), `PlannerAvailabilityProviding` and `ActivityProviding` are protocols.
- `CoachPlanner` takes the availability provider, the model planner and the fallback in its initialiser; tests pass stubs.
- Time is injected as `@Sendable () -> Date` and calendars are always passed explicitly, so time zone tests don't depend on the machine's settings.
- The app builds one `AppDependencies` value at launch (`.live`) and hands its members to `@Observable` feature models. Previews use `.preview`.

The only process-wide state is `SharedModelContainer.shared`, and it lives in the composition layer (`Shared/`), not in any package. App Intents are instantiated by the system with no parameters, so they need some well-known place to find the container.

**Rejected.**
- *`AppDependencyManager` / `@Dependency` for intents.* Clean on paper, but the dependency must be registered before the first intent runs, and for widget-driven intents the extension's entry point gives no reliable hook for that. A lazily created static in the composition root has no ordering problem.
- *A third-party DI container.* Unnecessary for a graph this size.

## 4. SwiftData concurrency model

**Context.** `ModelContext` is not `Sendable`; `ModelContainer` is. Swift 6 strict concurrency turns every mistake here into a compile error.

**Decision.**
- UI and intents use `container.mainContext` from `@MainActor` code only. Intents mark `perform()` as `@MainActor`.
- The widget's `TimelineProvider` runs off the main actor, so it creates a private `ModelContext(container)` per timeline request and never shares it.
- Domain logic (`Habit.toggle`, `markCompleted`, `WeekSummary.make`) takes a context or plain values as parameters and never reaches for a global one.
- The planners only ever see `WeekSummary`, a `Sendable` value type, so no model objects cross an actor boundary.
- ActivityKit calls are made with `Activity` values obtained from a `nonisolated` lookup, which keeps them in a disconnected region that the compiler lets us send to ActivityKit's async API.

**Rejected.**
- *A `@ModelActor` repository for all writes.* Useful for heavy background imports, but every write here is a single row from a tap. An actor would add hops and make `@Query`-driven UI lag behind the tap.
- *Batch `delete(model:)` for resetting demo data.* It fails on the habit/completion inverse relationship in the underlying store, so rows are deleted individually.

## 5. Streaks are stored as calendar days, not instants

**Context.** A streak is about the days the user *experienced*. Storing completion instants and bucketing them later breaks when the user travels or a DST change makes a day 23 or 25 hours long.

**Decision.** Each completion stores a `DayStamp` (`yyyy-MM-dd`) captured in the user's calendar at the moment of logging, plus the instant for auditing. Day arithmetic goes through `Calendar.date(byAdding: .day)` anchored at noon, because some zones skip midnight but none skip noon. Tests cover four DST zones, an east-bound flight, and Samoa's skipped 30 December 2011.

**Rejected.** *Instants plus `Calendar.isDate(_:inSameDayAs:)`.* Correct only if the user never changes time zone.

## 6. Foundation Models with a deterministic fallback

**Context.** The on-device model is unavailable on many devices, can be switched off, can still be downloading, and can refuse or fail a request.

**Decision.**
- `CoachPlanner` checks `SystemLanguageModel.default.availability` on every request, since it can change while the app runs.
- When available it uses guided generation into a `@Generable GeneratedPlan` with `@Guide` constraints on weekdays, workout kinds, minutes and session count. The result is clamped again before it reaches the UI.
- When unavailable, or on any generation error other than cancellation, it returns the `RuleBasedPlanner` output together with a human-readable reason that the Coach screen shows.
- The prompt text is built by a pure function and covered by tests, so prompt changes are reviewed like code.

**Rejected.**
- *Free-text generation plus parsing.* Brittle, and guided generation exists precisely to avoid it.
- *Hiding the Coach tab when the model is unavailable.* The rule-based planner is useful on its own, and a visible reason is more honest than a missing feature.
- *A server-side LLM.* Would need an account, a network and a privacy policy for health data. The on-device model needs none of those.

## 7. Generated Xcode project

**Decision.** `project.yml` is the source of truth and `*.xcodeproj` is ignored. Merge conflicts in `project.pbxproj` disappear, and target settings are reviewable in plain YAML. The generated `Info.plist` and entitlements files are committed because XcodeGen writes them deterministically and they document the app's capabilities.
