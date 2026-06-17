import Foundation

/// The `count` field in CourtListener paginated responses is polymorphic:
/// - Page-based endpoints (e.g. /courts/) return an integer total.
/// - Cursor-based endpoints (e.g. /people/) return a URL to fetch the count separately.
public enum ResponseCount: Sendable, Equatable {
    case total(Int)
    case deferred(URL)
}

extension ResponseCount: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let total = try? container.decode(Int.self) {
            self = .total(total)
            return
        }
        if let urlString = try? container.decode(String.self),
           let url = URL(string: urlString) {
            self = .deferred(url)
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected Int or URL string for pagination count"
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .total(let count):
            try container.encode(count)
        case .deferred(let url):
            try container.encode(url.absoluteString)
        }
    }
}
