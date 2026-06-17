import Foundation

/// A URL that carries a compile-time phantom type indicating which resource it points to.
/// The `Resource` type parameter is never instantiated — it exists purely as a label.
public struct ResourceURL<Resource>: Sendable, Codable, Hashable {
    public let url: URL

    public init(_ url: URL) {
        self.url = url
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(URL.self)
        self.url = raw
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(url)
    }
}
