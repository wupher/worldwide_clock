import SwiftUI
import WidgetKit

struct ClockEntry: TimelineEntry { let date: Date }

struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry { ClockEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        // TimeDataSource drives both the clock and calendar date independently of this timeline.
        completion(Timeline(entries: [ClockEntry(date: .now)], policy: .never))
    }
}

struct WorldClockWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 10) {
                    Label("WORLD CLOCK", systemImage: "globe.asia.australia")
                        .font(.system(size: 9, weight: .bold)).tracking(1)
                        .foregroundStyle(.secondary)
                    ForEach(City.allCases) { city in
                        HStack {
                            Text(city.name).font(.system(size: 12, weight: .medium))
                            Spacer(minLength: 4)
                            Text(.currentDate, format: city.clockFormat)
                                .font(.system(size: 19, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .environment(\.calendar, city.calendar)
                                .environment(\.timeZone, city.timeZone)
                        }
                    }
                }
                // Small widgets have a single tap target; the app offers all three choices.
                .widgetURL(URL(string: "worldwideclock://open")!)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("WORLD CLOCK", systemImage: "globe.asia.australia")
                        Spacer()
                        Text("24H")
                    }
                    .font(.system(size: 9, weight: .bold)).tracking(1.5)
                    .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ForEach(City.allCases) { city in
                            Link(destination: city.url) { ClockFace(city: city) }
                                .buttonStyle(.plain)
                                .accessibilityHint("Change your Mac’s time zone to \(city.name)")
                            if city != .bangkok { Divider() }
                        }
                    }
                    Text("SELECT A CITY TO SET MAC TIME ZONE")
                        .font(.system(size: 8, weight: .medium)).tracking(0.8)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Rectangle().fill(Color(nsColor: .windowBackgroundColor).gradient)
        }
    }
}

@main
struct WorldClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WorldwideClock", provider: ClockProvider()) { _ in
            WorldClockWidgetView()
        }
        .configurationDisplayName("Worldwide Clock")
        .description("Hong Kong, Tokyo and Bangkok. Select a city in the medium widget to change your Mac’s time zone.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
