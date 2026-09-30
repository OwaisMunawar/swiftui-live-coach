# Contributing

Thanks for taking a look. Issues and pull requests are welcome.

## Setup

1. Xcode 26 or later, plus [XcodeGen](https://github.com/yonaskolb/XcodeGen) and [SwiftLint](https://github.com/realm/SwiftLint): `brew install xcodegen swiftlint`.
2. `xcodegen generate`, then open `LiveCoach.xcodeproj`. Re-run `xcodegen generate` after adding or removing files; the project file is not committed.

## Before opening a pull request

```sh
swiftlint lint --strict
swift test --package-path Packages/CoachCore
swift test --package-path Packages/CoachIntelligence
swift test --package-path Packages/CoachHealth
xcodebuild -scheme LiveCoach -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build test
```

CI runs the same steps.

## Guidelines

- Keep domain logic in `CoachCore` and free of UI, globals and wall-clock time. Inject calendars and clocks.
- New logic in a package needs Swift Testing coverage. Time and date code should include at least one non-UTC time zone case.
- The build treats warnings as errors under Swift 6 strict concurrency. Please fix warnings rather than suppress them.
- Custom controls need VoiceOver labels and values, and text should use Dynamic Type styles.
- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat(core): ...`, `fix(widgets): ...`) and keep each commit focused.
- Update `CHANGELOG.md` under "Unreleased" for user-facing changes.
