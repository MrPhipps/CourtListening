import Foundation

enum ResponseDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()

        // Formatters are created once here and captured by the date-decoding closure. Keeping
        // them local (rather than static) avoids non-Sendable global mutable state under Swift 6
        // strict concurrency; they are only ever read (parsing), never reconfigured.
        let iso8601Full: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        let iso8601FractionalSeconds: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let dateOnly: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            if let date = iso8601Full.date(from: string) { return date }
            if let date = iso8601FractionalSeconds.date(from: string) { return date }
            if let date = dateOnly.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(string)"
            )
        }
        return decoder
    }()
}
