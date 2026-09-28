import Foundation

enum TimeZoneChangeError: LocalizedError {
    case cancelled
    case failed(String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .cancelled: "Time-zone change cancelled."
        case .failed(let message): message
        case .verificationFailed:
            "macOS did not retain the requested time zone. Check Date & Time settings and turn off automatic time-zone selection, then try again."
        }
    }
}

struct TimeZoneService: Sendable {
    static func script(for city: City) -> String {
        // Only fixed enum values reach the privileged command. Never interpolate a URL or user input.
        "do shell script \"/usr/sbin/systemsetup -settimezone '\(city.zoneID)'\" with administrator privileges"
    }

    static func currentZoneID() -> String {
        // Read fresh OS configuration rather than Foundation's cached default zone.
        let path = URL(fileURLWithPath: "/etc/localtime").resolvingSymlinksInPath().path
        if let range = path.range(of: "/zoneinfo/") {
            return String(path[range.upperBound...])
        }
        NSTimeZone.resetSystemTimeZone()
        return TimeZone.current.identifier
    }

    func change(to city: City) async throws {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", Self.script(for: city)]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(decoding: data, as: UTF8.self)
            guard process.terminationStatus == 0 else {
                if output.contains("(-128)") { throw TimeZoneChangeError.cancelled }
                throw TimeZoneChangeError.failed(output.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            guard Self.currentZoneID() == city.zoneID else {
                throw TimeZoneChangeError.verificationFailed
            }
        }.value
    }
}
