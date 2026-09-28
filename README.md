# Worldwide Clock

Native SwiftUI macOS app and WidgetKit desktop / Notification Center widget for Hong Kong, Tokyo, and Bangkok. Requires **macOS 15+** and Xcode 16+ to build. No third-party runtime dependencies.

## Build and use

```sh
bash scripts/test.sh
bash scripts/build.sh
open .build/Build/Products/Release/WorldwideClock.app
```

For a permanent installation, copy the built `WorldwideClock.app` to Applications and open it once. Right-click the desktop → **Edit Widgets** → search **Worldwide Clock**. Add the **medium** widget to get three independent city links. The small widget displays all three clocks, but its single click target opens the app to choose a city.

The local build uses ad-hoc signing. If macOS does not list the widget, open `WorldwideClock.xcodeproj`, select your Apple development team for both targets, build and run the app, then reopen the widget gallery. Distribution to other Macs requires appropriate Developer ID signing and notarization; the local build is not a notarized installer.

## Changing the Mac time zone

Click a city in the medium widget or companion app. The app runs the built-in `/usr/sbin/systemsetup -settimezone` command through Apple's administrator authorization dialog. Cancel leaves the requested change unapplied. The app checks the resulting OS time-zone identifier before reporting success. It never collects or stores a password.

Only `Asia/Hong_Kong`, `Asia/Tokyo`, and `Asia/Bangkok` can reach the command. Incoming links are validated against these fixed city choices. The widget is sandboxed; the companion app is deliberately unsandboxed to support administrator-authorized system configuration. This implementation is intended for direct/local distribution, not a Mac App Store submission.

If **Set time zone automatically using your current location** is enabled, macOS may restore the location-derived zone. Turn that option off in System Settings → General → Date & Time when using manual switching. The app includes a shortcut to those settings. It does not change network clock synchronization, the actual UTC instant, or that automatic-location preference.

## Implementation

- `Shared/City.swift`: IANA time zones, 24-hour formats, strict city URL routing.
- `Shared/ClockFace.swift`: shared live clock presentation.
- Live clock text uses only Foundation's built-in format styles, with both the environment calendar and time zone set per city. Custom `DiscreteFormatStyle` types cannot be decoded by the separate WidgetKit renderer and cause placeholder bars, even when they render correctly inside the app.
- `Widget/ClockWidget.swift`: small and medium widgets. `Text(.currentDate, format:)` updates clock and date through the system's time data source, independently of timeline reloads.
- `App/TimeZoneService.swift`: authorization, allowlisted command, cancellation, post-change verification.
- `App/WorldwideClockApp.swift`: companion window and widget link handling.
- `Tests/ClockTests.swift`: time conversion, date rollover, format update boundaries, rejected links, and command constraints. Tests do **not** modify the machine's time zone.

`project.yml` is the XcodeGen source. The generated Xcode project is committed alongside it; run `xcodegen generate` after changing the specification.

## Manual acceptance checks

1. Add both widget sizes and confirm all three times match the companion app across a minute boundary and after sleep/wake.
2. Click Tokyo in the medium widget; cancel authorization and verify the system zone is unchanged.
3. Repeat and authorize; check Date & Time shows Tokyo and the app reports success. Repeat for Bangkok and Hong Kong.
4. Close the companion window, then click a widget city to verify cold launch / reopening.
5. If automatic time-zone selection is enabled, disable it in Settings and retry manual selection.

The privileged change and actual WidgetKit gallery behavior require interactive validation on the Mac; automated tests intentionally do not authorize a system change.

After updating, quit and reopen the rebuilt app to request a widget timeline reload. If an old placeholder remains cached, remove that widget and add it again.

References: [Apple widget links](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity), [live time data](https://developer.apple.com/documentation/swiftui/timedatasource), [administrator authorization](https://developer.apple.com/library/archive/technotes/tn2065/_index.html).
