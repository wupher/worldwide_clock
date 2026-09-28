import SwiftUI

struct ClockFace: View {
    let city: City
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 8) {
            Text(city.code)
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text(city.name)
                .font(.system(size: compact ? 11 : 14, weight: .semibold))
                .lineLimit(1)
            Text(.currentDate, format: city.clockFormat)
                .font(.system(size: compact ? 23 : 32, weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(.currentDate, format: city.dateFormat)
                .font(.system(size: compact ? 9 : 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Live Text takes its calendar from the environment, including that calendar's zone.
        // Both must be set. Keep native format styles so WidgetKit can decode the view archive.
        .environment(\.calendar, city.calendar)
        .environment(\.timeZone, city.timeZone)
        .accessibilityElement(children: .combine)
    }
}
