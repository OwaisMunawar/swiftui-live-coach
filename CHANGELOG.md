# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/OwaisMunawar/swiftui-live-coach/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/OwaisMunawar/swiftui-live-coach/releases/tag/v0.1.0
