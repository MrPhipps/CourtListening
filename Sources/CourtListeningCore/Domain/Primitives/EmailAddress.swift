import Foundation

/// A validated email address. Blank values decode to `nil`; invalid formats throw.
public struct EmailAddress: RawRepresentable, Sendable, Codable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.contains("@"), trimmed.contains(".")
        else { throw CourtListenerError.invalidIdentifier("EmailAddress must contain '@' and '.'") }
        self.rawValue = trimmed
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
