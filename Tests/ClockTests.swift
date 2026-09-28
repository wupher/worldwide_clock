import Foundation

@main
struct ClockTests {
    static func main() throws {
        let parser = ISO8601DateFormatter()
        let midnight = parser.date(from: "2026-09-28T16:30:00Z")!
        let expected = [City.hongKong: "00:30", .tokyo: "01:30", .bangkok: "23:30"]
        for city in City.allCases {
            precondition(city.clockFormat.format(midnight) == expected[city], "Clock conversion: \(city)")
            let liveStyle = city.clockFormat
            precondition(liveStyle.format(midnight) == expected[city])
            let decoded = try JSONDecoder().decode(Date.VerbatimFormatStyle.self, from: JSONEncoder().encode(liveStyle))
            precondition(decoded.format(midnight) == expected[city], "Widget format serialization")
            precondition(city.calendar.timeZone == city.timeZone, "Live Text calendar must use the city's zone")
            precondition(City.from(url: city.url) == city, "Deep link round trip")
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = city.timeZone
            precondition(calendar.component(.day, from: midnight) == (city == .bangkok ? 28 : 29))
            // Verify the dynamic format advances exactly at the next minute boundary.
            let next = city.clockFormat.discreteInput(after: midnight)!
            precondition(next > midnight && next.timeIntervalSince(midnight) <= 60.01)
            precondition(city.clockFormat.format(next) != city.clockFormat.format(midnight))
            for month in [1, 7] {
                let date = calendar.date(from: DateComponents(year: 2026, month: month, day: 1))!
                let hours = city == .tokyo ? 9 : city == .hongKong ? 8 : 7
                precondition(city.timeZone.secondsFromGMT(for: date) == hours * 3600)
            }
            let script = TimeZoneService.script(for: city)
            precondition(script.contains("/usr/sbin/systemsetup -settimezone '\(city.zoneID)'"))
            precondition(script.hasSuffix("with administrator privileges"))
        }
        for invalid in [
            "https://city/tokyo", "worldwideclock://city/london", "worldwideclock://city/tokyo/extra",
            "worldwideclock://city/tokyo?command=anything", "worldwideclock://city/tokyo#extra",
            "worldwideclock://user@city/tokyo", "worldwideclock://city:12/tokyo",
            "worldwideclock://city/Asia/Tokyo", "worldwideclock://city/tokyo%3Bwhoami"
        ] {
            precondition(City.from(url: URL(string: invalid)!) == nil, "Reject \(invalid)")
        }
        precondition(TimeZone(identifier: TimeZoneService.currentZoneID()) != nil)
        print("PASS: city times, midnight rollover, winter/summer offsets, live minute boundaries, URL validation, and privileged command allowlist.")
        print("System time zone was read only; no authorization or changes were performed.")
    }
}
