# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.2] - 2026-11-25

### Fixed
- The weekly plan ignored weekly goals. A habit set to "3 a week" and done three times was flagged as weak ("Protect run, done on 3 of 7 days") and pulled the Habits percentage down. Habits with a goal are now measured against that goal, are only flagged when they fall short of it, and the rationale states the goal. The on-device model prompt includes each habit's goal as well.

## [0.2.1] - 2026-11-19

### Added
- UI tests for the weekly-goal flow: adding a habit with a goal, Today captions, detail tiles, changing the goal from the habit menu and the demo data's captions.

### Fixed
- The habit detail streak tile for weekly habits was truncated ("Week str...") at the default text size; it now reads "Streak" with the value in weeks.

## [0.2.0] - 2026-11-19

### Added
- Weekly goals: a habit can target 1 to 6 check-ins per calendar week, with progress on the Today row, a "This week" tile and a week streak on the habit detail, and a goal picker when adding a habit or from its menu.
- `WeeklyGoal`, `WeeklyProgress` and `DayStamp.startOfWeek` in `CoachCore`, tested across first-weekday settings, DST, the date line and year boundaries.
- Two demo habits with weekly goals.

### Changed
- `Habit` gains an optional `weeklyTarget`; existing stores migrate in place.

## [0.1.0] - 2026-09-30

### Added
- Daily habits with time-zone and DST-safe streaks, stored in SwiftData.
- Today screen with progress ring, habit detail with streak stats and a 12-week heatmap.
- Timed workout and focus sessions with a Live Activity on the Lock Screen and Dynamic Island, including Pause/Resume and Finish buttons.
- Interactive Home Screen widget for checking off today's habits.
- App Intents and App Shortcuts: start a workout, log a habit.
- Read-only HealthKit integration for steps and active energy, with an empty state when no data exists.
- Weekly Coach plan generated on-device with Foundation Models, falling back to a rule-based planner when Apple Intelligence is unavailable.
- `livecoach://` deep links and a `-demoData` launch argument.
- CI with SwiftLint, package tests and a simulator build and test.

[Unreleased]: https://github.com/OwaisMunawar/swiftui-live-coach/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/OwaisMunawar/swiftui-live-coach/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/OwaisMunawar/swiftui-live-coach/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/OwaisMunawar/swiftui-live-coach/releases/tag/v0.1.0
