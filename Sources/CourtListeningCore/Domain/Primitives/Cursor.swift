import Foundation

/// An opaque pagination cursor returned by the CourtListener API.
/// Cursors are base64-encoded offsets; blank values are rejected at construction time.
public struct Cursor: Sendable, Codable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty
        else { throw CourtListenerError.invalidIdentifier("Cursor cannot be blank") }
        self.rawValue = trimmed
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
