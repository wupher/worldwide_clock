import AppKit
import SwiftUI
import WidgetKit

@MainActor
final class ClockModel: ObservableObject {
    @Published var currentZone = TimeZoneService.currentZoneID()
    @Published var changing: City?
    @Published var message: String?
    @Published var failed = false

    func refresh() { currentZone = TimeZoneService.currentZoneID() }

    func change(to city: City) {
        guard changing == nil else { return }
        refresh()
        guard currentZone != city.zoneID else {
            message = "Your Mac already uses \(city.name) time."
            failed = false
            return
        }
        changing = city
        message = "Authorize the change to \(city.name) in the macOS prompt."
        failed = false
        Task {
            do {
                try await TimeZoneService().change(to: city)
                message = "Mac time zone changed to \(city.name)."
            } catch {
                message = error.localizedDescription
                failed = true
            }
            refresh()
            changing = nil
        }
    }
}

@main
struct WorldwideClockApp: App {
    @StateObject private var model = ClockModel()

    var body: some Scene {
        Window("Worldwide Clock", id: "clock") {
            ClockWindow(model: model)
                .task { WidgetCenter.shared.reloadTimelines(ofKind: "WorldwideClock") }
                .onOpenURL { url in
                    NSApp.activate(ignoringOtherApps: true)
                    if let city = City.from(url: url) { model.change(to: city) }
                }
        }
        .defaultSize(width: 590, height: 420)
        .windowResizability(.contentSize)
    }
}

struct ClockWindow: View {
    @ObservedObject var model: ClockModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 32)).foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Worldwide Clock").font(.title2.bold())
                    Text("Three cities. One glance.").foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 12) {
                ForEach(City.allCases) { city in
                    Button { model.change(to: city) } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            ClockFace(city: city)
                            Label(model.currentZone == city.zoneID ? "Mac time zone" : "Use on this Mac",
                                  systemImage: model.currentZone == city.zoneID ? "checkmark.circle.fill" : "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(model.currentZone == city.zoneID ? Color.teal : Color.secondary)
                        }
                        .padding(16)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(model.currentZone == city.zoneID ? Color.teal.opacity(0.7) : .clear))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.changing != nil)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Mac time zone: \(model.currentZone)").font(.callout.weight(.medium))
                if let message = model.message {
                    HStack(spacing: 8) {
                        if model.changing != nil { ProgressView().controlSize(.small) }
                        Text(message).foregroundStyle(model.failed ? Color.orange : Color.secondary)
                    }.font(.callout).textSelection(.enabled)
                }
                Text("Changing the system time zone requires administrator authorization. If macOS switches it back, turn off “Set time zone automatically” in Date & Time.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Open Date & Time Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Date-Time-Settings.extension")!)
                }.buttonStyle(.link).font(.caption)
            }
            Divider()
            Text("Add the widget: right-click your desktop → Edit Widgets → Worldwide Clock. Use the medium size for individual city buttons.")
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding(26)
        .frame(width: 590)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in model.refresh() }
    }
}
