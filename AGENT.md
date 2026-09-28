# Project guidance

## Scope and communication

- Read `README.md` and the relevant source before changing behavior.
- Ask for clarification when requirements or key prerequisites are unclear.
- Be direct about incorrect assumptions, bugs, risks, and verification limits.
- Prefer small, maintainable changes that follow the existing implementation. Avoid unnecessary dependencies and abstractions.
- During reviews, prioritize concrete bugs, regressions, edge cases, and missing tests.

## Project overview

Worldwide Clock is a native macOS app and WidgetKit extension showing Hong Kong, Tokyo, and Bangkok. The companion app can change the Mac's system time zone after administrator authorization.

- Swift 6, SwiftUI, Foundation, AppKit, and WidgetKit.
- Requires macOS 15+ and Xcode 16+; no third-party runtime dependencies.
- This is not a JavaScript project despite its parent directory name.
- The app supports direct/local distribution. Its current privilege model is not intended for Mac App Store distribution.

## Source map

- `Shared/City.swift`: fixed city choices, IANA zone identifiers, calendars, native date/time formats, and strict deep-link parsing.
- `Shared/ClockFace.swift`: clock presentation shared by the app and medium widget.
- `App/WorldwideClockApp.swift`: app entry point, main-actor UI model, window, URL handling, and refresh notifications.
- `App/TimeZoneService.swift`: privileged command construction, authorization execution, cancellation handling, and OS time-zone verification.
- `Widget/ClockWidget.swift`: timeline provider and small/medium widget layouts and links.
- `Tests/ClockTests.swift`: standalone executable checks using preconditions; not an XCTest target.
- `project.yml`: XcodeGen project specification.
- `WorldwideClock.xcodeproj/`: checked-in generated Xcode project.
- `Config/`: app/extension property lists and widget entitlements, referenced by the project specification.
- `scripts/`: build and test entry points. Generated output belongs in `.build/`.

## Development commands

Run commands from the repository root:

```sh
bash scripts/test.sh
bash scripts/build.sh
```

The test script compiles the city model, time-zone service, and test executable with Swift 6. It reads the current system time zone but does not change it or request authorization. The build script builds both targets in Release mode with ad-hoc signing.

Build output: `.build/Build/Products/Release/WorldwideClock.app`.

When changing project configuration, edit `project.yml` and run:

```sh
xcodegen generate
```

Review the resulting Xcode project and configuration changes together. Ordinary builds use the checked-in project and do not require XcodeGen. Do not rely solely on hand edits to generated project settings.

## Behavior to preserve

- Keep city and zone values centralized in `City`. Privileged commands must receive fixed enum-backed zone identifiers, never raw URLs or arbitrary input.
- Preserve strict validation of `worldwideclock://city/<city-id>` links, including rejection of credentials, ports, queries, fragments, and unsupported paths.
- `worldwideclock://open` opens the companion app without selecting a city. The small widget has one click target; the medium widget provides individual city links.
- Keep administrator authorization in the companion app. The widget is sandboxed; the companion app is deliberately unsandboxed with hardened runtime enabled.
- Never collect or store administrator passwords. Preserve cancellation handling and verify the resulting OS zone before reporting success.
- Read fresh OS time-zone configuration when verifying changes; do not assume Foundation's cached default zone reflects the latest system state.
- Changing a time zone must not change the UTC instant, network clock synchronization, or the automatic location-based time-zone preference.
- Preserve `@MainActor` isolation for UI state and keep blocking process execution off the main actor. Prevent overlapping time-zone change requests.

## Live clock rendering

- Use `Text(.currentDate, format:)` with Foundation's built-in format styles for live clock and date text.
- Set both the environment calendar and environment time zone per city. The calendar must carry that city's zone.
- Do not introduce custom `DiscreteFormatStyle` types for widget text: the separate WidgetKit renderer cannot decode them reliably, even if app rendering succeeds.
- Preserve the 24-hour, zero-based hour display and city-local date rollover.
- The current timeline uses `.never` because the system time data source drives the displayed clock and date. Do not add frequent timeline reloads just to advance the clock.

## Validation and delivery

- For logic changes, run `bash scripts/test.sh` and add focused regression checks for affected behavior. If adding test source files, update the test script's explicit compiler inputs.
- For SwiftUI, widget, or project configuration changes, run `bash scripts/build.sh`. Run both scripts for changes shared across logic and UI targets.
- Keep automated tests free of privileged system changes.
- Actual widget rendering, gallery registration, sleep/wake updates, authorization, and cold-launch link handling require interactive validation. Use the manual acceptance checks in `README.md` when applicable; do not claim these are proven by compilation or executable tests.
- Only perform an actual system time-zone change when the user has authorized that action.
- Report what changed, which checks ran, and any unverified behavior or unavailable tooling. Update `README.md` when user-visible behavior or setup changes.
