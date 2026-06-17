import Foundation

/// A non-empty, non-whitespace-only string. Rejects blank values at construction time.
public struct NonEmptyString: RawRepresentable, Sendable, Codable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        guard !rawValue.trimmingCharacters(in: .whitespaces).isEmpty
        else { throw CourtListenerError.invalidIdentifier("String cannot be blank") }
        self.rawValue = rawValue
    }

    public init(rawValue: String) throws {
        try self.init(rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        try self.init(raw)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
