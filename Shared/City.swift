import Foundation

enum City: String, CaseIterable, Identifiable, Sendable, Codable {
    case hongKong = "hong-kong"
    case tokyo
    case bangkok

    var id: String { rawValue }
    var name: String {
        switch self {
        case .hongKong: "Hong Kong"
        case .tokyo: "Tokyo"
        case .bangkok: "Bangkok"
        }
    }
    var zoneID: String {
        switch self {
        case .hongKong: "Asia/Hong_Kong"
        case .tokyo: "Asia/Tokyo"
        case .bangkok: "Asia/Bangkok"
        }
    }
    var code: String {
        switch self {
        case .hongKong: "HKG"
        case .tokyo: "TYO"
        case .bangkok: "BKK"
        }
    }
    var timeZone: TimeZone { TimeZone(identifier: zoneID)! }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
    var url: URL { URL(string: "worldwideclock://city/\(rawValue)")! }

    static func from(url: URL) -> City? {
        guard url.scheme == "worldwideclock", url.host == "city",
              url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil else { return nil }
        return allCases.first { url.path == "/\($0.rawValue)" }
    }

    var clockFormat: Date.VerbatimFormatStyle {
        .init(format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
              locale: Locale(identifier: "en_US_POSIX"), timeZone: timeZone,
              calendar: calendar)
    }
    var dateFormat: Date.FormatStyle {
        Date.FormatStyle(calendar: calendar, timeZone: timeZone).weekday(.abbreviated).month(.abbreviated).day()
    }
    func utcLabel(at date: Date) -> String {
        let minutes = timeZone.secondsFromGMT(for: date) / 60
        return String(format: "UTC%+d:%02d", minutes / 60, abs(minutes % 60))
    }
}
